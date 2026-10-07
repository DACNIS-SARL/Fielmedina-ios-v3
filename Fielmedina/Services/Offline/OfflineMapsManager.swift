import Foundation
import CoreLocation
import MapKit
import MapboxMaps
import MapboxCommon
import MapboxNavigationCore
import MapboxNavigationNative_Private
import MapboxDirections
import Turf

extension Notification.Name {
    static let tileRegionProgressChanged = Notification.Name("tile_region_progress_changed")
    static let tileRegionCompleted = Notification.Name("tile_region_completed")
    static let tileRegionFailed = Notification.Name("tile_region_failed")
}

private final class ErrorSlot: @unchecked Sendable {
    private let lock = NSLock()
    private var error: Error?

    func store(_ newError: Error) {
        lock.lock()
        defer { lock.unlock() }
        error = newError
    }

    var value: Error? {
        lock.lock()
        defer { lock.unlock() }
        return error
    }
}

final class OfflineMapsManager: @unchecked Sendable {
    static let shared = OfflineMapsManager()
    
    private let offlineManager = OfflineManager()
    private var tileStore: TileStore {
        OfflineTileStore.shared
    }
    
    private(set) var activeDownloads: [String: Double] = [:]

    @MainActor
    static var isUserRegionDownloadActive: Bool {
        !OfflineMapsManager.shared.activeDownloads.isEmpty
    }

    private static let lastRegionRefreshKey = "offline_maps_last_region_refresh"
    private static let regionRefreshInterval: TimeInterval = 7 * 24 * 60 * 60
    private static let regionGeometryKey = "offline_maps_region_geometry"

    static func recordRegionGeometry(regionId: String, latitude: Double, longitude: Double, radius: Double) {
        var map = UserDefaults.standard.dictionary(forKey: regionGeometryKey) as? [String: String] ?? [:]
        map[regionId] = "\(latitude),\(longitude),\(radius)"
        UserDefaults.standard.set(map, forKey: regionGeometryKey)
    }

    private static func regionGeometryChanged(regionId: String, city: OfflineCityDataStore.CachedCity) -> Bool {
        guard let map = UserDefaults.standard.dictionary(forKey: regionGeometryKey) as? [String: String],
              let stamp = map[regionId] else { return true }
        let parts = stamp.split(separator: ",").compactMap { Double($0) }
        guard parts.count == 3 else { return true }
        let stored = CLLocation(latitude: parts[0], longitude: parts[1])
        let current = CLLocation(latitude: city.latitude, longitude: city.longitude)
        return stored.distance(from: current) > 50 || abs(parts[2] - city.radius) > 1
    }

    private static func refreshCitiesMetadata() async {
        do {
            let query = FielmedinaAPI.GetOfflineCitiesQuery(isActive: .some(true))
            let data = try await Network.shared.apollo.fetchFresh(query: query)
            let cached = data.offlineCities.compactMap { city -> OfflineCityDataStore.CachedCity? in
                guard let lat = Double(city.latitude),
                      let lon = Double(city.longitude),
                      let cityIdStr = city.city?.id, let cityId = Int32(cityIdStr) else { return nil }
                return OfflineCityDataStore.CachedCity(
                    id: city.regionId,
                    cityId: cityId,
                    name: city.name,
                    latitude: lat,
                    longitude: lon,
                    radius: city.radius
                )
            }
            if !cached.isEmpty {
                OfflineCityDataStore.shared.updateCitiesCache(cities: cached)
            }
        } catch { }
    }

    private init() { }

    func downloadRegion(
        id: String,
        name: String,
        coordinate: CLLocationCoordinate2D,
        radius: CLLocationDistance,
        silent: Bool = false,
        progress: @escaping (Double) -> Void,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        downloadStylePacks(name: name, progress: progress) { [weak self] result in
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success:
                self?.downloadNavigationTiles(
                    id: id,
                    coordinate: coordinate,
                    radius: radius,
                    silent: silent,
                    progress: progress,
                    completion: completion
                )
            }
        }
    }

    func refreshDownloadedRegionsIfNeeded() {
        guard NetworkMonitor.shared.isConnected else { return }

        Task { [weak self] in
            await Self.refreshCitiesMetadata()

            let defaults = UserDefaults.standard
            let weeklyRefreshDue: Bool
            if let last = defaults.object(forKey: Self.lastRegionRefreshKey) as? Date {
                weeklyRefreshDue = Date().timeIntervalSince(last) >= Self.regionRefreshInterval
            } else {
                weeklyRefreshDue = true
            }

            self?.fetchDownloadedRegionIds { [weak self] regionIds in
                guard let self else { return }
                if weeklyRefreshDue {
                    defaults.set(Date(), forKey: Self.lastRegionRefreshKey)
                }
                guard !regionIds.isEmpty else { return }

                let store = OfflineCityDataStore.shared
                let cities = store.cachedCities
                for regionId in regionIds {
                    guard self.activeDownloads[regionId] == nil else { continue }
                    let mappedCityId = store.cityId(for: regionId)
                    guard let city = cities.first(where: { $0.cityId == mappedCityId })
                            ?? cities.first(where: { $0.id == regionId }) else { continue }

                    let hasMoved = Self.regionGeometryChanged(regionId: regionId, city: city)
                    guard hasMoved || weeklyRefreshDue else { continue }

                    self.downloadRegion(
                        id: regionId,
                        name: city.name,
                        coordinate: CLLocationCoordinate2D(latitude: city.latitude, longitude: city.longitude),
                        radius: city.radius,
                        silent: true,
                        progress: { _ in },
                        completion: { result in
                            if case .success = result {
                                Self.recordRegionGeometry(
                                    regionId: regionId,
                                    latitude: city.latitude,
                                    longitude: city.longitude,
                                    radius: city.radius
                                )
                            }
                        }
                    )
                }
            }
        }
    }
    
    private func downloadStylePacks(
        name: String,
        progress: @escaping (Double) -> Void,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        let primaryStyleURI: StyleURI = .standard
        guard let stylePackLoadOptions = StylePackLoadOptions(
            glyphsRasterizationMode: .ideographsRasterizedLocally,
            metadata: ["name": name, "updatedAt": Date().timeIntervalSince1970]
        ) else {
            completion(.failure(NSError(domain: "OfflineManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create StylePackLoadOptions"])))
            return
        }

        _ = offlineManager.loadStylePack(
            for: primaryStyleURI,
            loadOptions: stylePackLoadOptions
        ) { packProgress in
            DispatchQueue.main.async {
                let completed = Double(packProgress.completedResourceCount)
                let required = max(Double(packProgress.requiredResourceCount), 1)
                progress(min(completed / required, 1) * 0.15)
            }
        } completion: { result in
            DispatchQueue.main.async {
                switch result {
                case .failure(let error):
                    completion(.failure(error))
                case .success:
                    self.downloadNavigationStylePacks(name: name, completion: completion)
                }
            }
        }
    }

    private func downloadNavigationStylePacks(
        name: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        let navigationStyles = [
            StyleURI(rawValue: "mapbox://styles/mapbox-dash/standard-navigation")
        ].compactMap { $0 }
        let group = DispatchGroup()
        let lastError = ErrorSlot()

        for styleURI in navigationStyles {
            group.enter()
            guard let options = StylePackLoadOptions(
                glyphsRasterizationMode: .ideographsRasterizedLocally,
                metadata: ["name": name, "updatedAt": Date().timeIntervalSince1970]
            ) else {
                lastError.store(NSError(domain: "OfflineManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create StylePackLoadOptions"]))
                group.leave()
                continue
            }

            _ = offlineManager.loadStylePack(for: styleURI, loadOptions: options) { _ in } completion: { result in
                if case .failure(let error) = result {
                    lastError.store(error)
                }
                group.leave()
            }
        }

        group.notify(queue: .main) {
            if let error = lastError.value {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
    private static let navigationTilesDataset = ProfileIdentifier.walking.rawValue

    private static func fetchLatestNavigationTilesVersion() async -> String? {
        let token = MapboxOptions.accessToken
        guard !token.isEmpty,
              let url = URL(string: "https://api.mapbox.com/route-tiles/v2/\(navigationTilesDataset)/versions?access_token=\(token)") else {
            return nil
        }
        struct VersionsResponse: Decodable { let availableVersions: [String] }
        do {
            let request = URLRequest(url: url, timeoutInterval: 10)
            let (data, _) = try await URLSession.shared.data(for: request)
            let response = try JSONDecoder().decode(VersionsResponse.self, from: data)
            let latest = response.availableVersions.sorted().last
            if let latest {
                NavigationTilesVersionStore.stored = latest
            }
            return latest
        } catch {
            return nil
        }
    }

    static func resolveNavigationTilesVersionIfNeeded() async {
        guard NavigationTilesVersionStore.stored == nil else { return }
        for _ in 0..<10 where !NetworkMonitor.shared.isConnected {
            try? await Task.sleep(for: .milliseconds(300))
        }
        guard NetworkMonitor.shared.isConnected else { return }
        _ = await fetchLatestNavigationTilesVersion()
    }

    private func downloadNavigationTiles(
        id: String,
        coordinate: CLLocationCoordinate2D,
        radius: CLLocationDistance,
        silent: Bool = false,
        progress: @escaping (Double) -> Void,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        Task { @MainActor in
            var navigationDescriptors: [TilesetDescriptor] = []
            if let version = await Self.fetchLatestNavigationTilesVersion() {
                navigationDescriptors.append(Self.buildNavigationDescriptor(version: version))
                let runtimeVersion = NavigationTilesVersionStore.pinnedAtLaunch
                if !runtimeVersion.isEmpty && runtimeVersion != version {
                    navigationDescriptors.append(Self.buildNavigationDescriptor(version: runtimeVersion))
                }
            } else {
                navigationDescriptors.append(
                    MapboxNavigationProviderStore.shared.getLatestNavigationTilesetDescriptor()
                )
            }
            self.loadTileRegion(
                id: id,
                coordinate: coordinate,
                radius: radius,
                navigationDescriptors: navigationDescriptors,
                silent: silent,
                progress: progress,
                completion: completion
            )
        }
    }

    private static func buildNavigationDescriptor(version: String) -> TilesetDescriptor {
        (OfflineMapsManager.self as NavigationDescriptorBuilding.Type)
            .buildPinnedNavigationDescriptor(version: version)
    }

    private func loadTileRegion(
        id: String,
        coordinate: CLLocationCoordinate2D,
        radius: CLLocationDistance,
        navigationDescriptors: [TilesetDescriptor],
        silent: Bool,
        progress: @escaping (Double) -> Void,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        let zoomRange: ClosedRange<UInt8> = 0...16

        let styleURIs: [StyleURI] = [
            .standard,
            StyleURI(rawValue: "mapbox://styles/mapbox-dash/standard-navigation")
        ].compactMap { $0 }

        let tilesetDescriptors = styleURIs.map { styleURI in
            let tilesetDescriptorOptions = TilesetDescriptorOptions(
                styleURI: styleURI,
                zoomRange: zoomRange,
                tilesets: nil
            )
            return offlineManager.createTilesetDescriptor(for: tilesetDescriptorOptions)
        }

        let geometry = Geometry.polygon(Polygon(center: coordinate, radiusMeters: radius))

        let descriptors = tilesetDescriptors + navigationDescriptors

        guard let tileRegionLoadOptions = TileRegionLoadOptions(
            geometry: geometry,
            descriptors: descriptors,
            metadata: ["name": id],
            acceptExpired: true
        ) else {
            completion(.failure(NSError(domain: "OfflineManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create TileRegionLoadOptions"])))
            return
        }
        
        if !silent {
            activeDownloads[id] = 0.01
        }

        tileStore.loadTileRegion(
            forId: id,
            loadOptions: tileRegionLoadOptions
        ) { [weak self] tileProgress in
            DispatchQueue.main.async {
                let completed = Double(tileProgress.completedResourceCount)
                let required = max(Double(tileProgress.requiredResourceCount), 1)
                let currentProgress = 0.15 + (min(completed / required, 1) * 0.85)

                progress(currentProgress)

                if !silent {
                    self?.activeDownloads[id] = currentProgress
                    NotificationCenter.default.post(
                        name: .tileRegionProgressChanged,
                        object: nil,
                        userInfo: ["id": id, "progress": currentProgress]
                    )
                }
            }
        } completion: { [weak self] result in
            DispatchQueue.main.async {
                if !silent {
                    self?.activeDownloads.removeValue(forKey: id)
                }
                switch result {
                case .success:
                    if !silent {
                        NotificationCenter.default.post(name: .tileRegionCompleted, object: nil, userInfo: ["id": id])
                        Task { @MainActor in
                            MetaEvents.logOfflineRegionDownloaded(regionId: id)
                        }
                    }
                    completion(.success(()))
                case .failure(let error):
                    if !silent {
                        NotificationCenter.default.post(name: .tileRegionFailed, object: nil, userInfo: ["id": id, "error": error.localizedDescription])
                    }
                    completion(.failure(error))
                }
            }
        }
    }
    
    func removeRegion(id: String, completion: @escaping (Result<Void, Error>) -> Void) {
        tileStore.removeTileRegion(forId: id)
        DispatchQueue.main.async {
            completion(.success(()))
        }
    }
    
    func fetchDownloadedRegionIds(completion: @escaping ([String]) -> Void) {
        tileStore.allTileRegions { result in
            switch result {
            case .success(let regions):
                DispatchQueue.main.async {
                    completion(regions.map { $0.id })
                }
            case .failure:
                DispatchQueue.main.async {
                    completion([])
                }
            }
        }
    }
    
    
    func observeTileRegions(observer: TileStoreObserver) -> Cancelable {
        return tileStore.subscribe(observer)
    }
}


private protocol NavigationDescriptorBuilding {
    static func buildPinnedNavigationDescriptor(version: String) -> TilesetDescriptor
}

extension OfflineMapsManager: NavigationDescriptorBuilding {}

@available(iOS, deprecated: 1.0)
extension OfflineMapsManager {
    static func buildPinnedNavigationDescriptor(version: String) -> TilesetDescriptor {
        TilesetDescriptorFactory.build(
            forDataset: navigationTilesDataset,
            version: version,
            includeAdas: false
        )
    }
}

private extension Polygon {
    init(center: CLLocationCoordinate2D, radiusMeters: CLLocationDistance) {
        let region = MKCoordinateRegion(
            center: center,
            latitudinalMeters: radiusMeters * 2,
            longitudinalMeters: radiusMeters * 2
        )
        
        let latDelta = region.span.latitudeDelta / 2
        let lonDelta = region.span.longitudeDelta / 2
        
        let topLeft = CLLocationCoordinate2D(
            latitude: center.latitude + latDelta,
            longitude: center.longitude - lonDelta
        )
        let topRight = CLLocationCoordinate2D(
            latitude: center.latitude + latDelta,
            longitude: center.longitude + lonDelta
        )
        let bottomRight = CLLocationCoordinate2D(
            latitude: center.latitude - latDelta,
            longitude: center.longitude + lonDelta
        )
        let bottomLeft = CLLocationCoordinate2D(
            latitude: center.latitude - latDelta,
            longitude: center.longitude - lonDelta
        )
        
        self.init([[topLeft, topRight, bottomRight, bottomLeft, topLeft]])
    }
}
