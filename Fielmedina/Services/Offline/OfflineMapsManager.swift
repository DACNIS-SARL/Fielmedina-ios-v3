//
//  OfflineMapsManager.swift
//  Fielmedina
//
//  Created by Aslan on 1/25/26.
//

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

final class OfflineMapsManager {
    static let shared = OfflineMapsManager()
    
    private let offlineManager = OfflineManager()
    private var tileStore: TileStore {
        OfflineTileStore.shared
    }
    
    // Track active downloads: RegionId -> Progress (0.0...1.0)
    private(set) var activeDownloads: [String: Double] = [:]

    private static let lastRegionRefreshKey = "offline_maps_last_region_refresh"
    private static let regionRefreshInterval: TimeInterval = 7 * 24 * 60 * 60
    private static let regionGeometryKey = "offline_maps_region_geometry"

    /// Remembers the geometry a region was downloaded with, so coordinate fixes in the
    /// backend (e.g. a wrong longitude) trigger an automatic re-download.
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

    /// Network-first re-fetch of the offline cities so backend coordinate/radius fixes
    /// reach devices without requiring a visit to the Settings screen.
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

    /// Keeps downloaded regions healthy. Runs on every app foreground (online only):
    /// - Regions whose city geometry changed since download (e.g. a backend coordinate
    ///   fix like Sidi Bou Said's wrong longitude) are re-downloaded immediately.
    /// - All regions get an incremental refresh weekly, so the offline navigation tiles
    ///   stay pinned to a routing-tiles version the navigator can still use — without
    ///   this, offline routing eventually fails until a manual delete + re-download.
    /// The offline-cities metadata is re-fetched network-first before deciding, so
    /// backend fixes propagate without requiring a visit to the Settings screen.
    func refreshDownloadedRegionsIfNeeded() {
        guard NetworkMonitor.shared.isConnected else { return }

        Task {
            await Self.refreshCitiesMetadata()

            let defaults = UserDefaults.standard
            let weeklyRefreshDue: Bool
            if let last = defaults.object(forKey: Self.lastRegionRefreshKey) as? Date {
                weeklyRefreshDue = Date().timeIntervalSince(last) >= Self.regionRefreshInterval
            } else {
                weeklyRefreshDue = true
            }

            self.fetchDownloadedRegionIds { [weak self] regionIds in
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
                    // Regions downloaded by older app versions may miss the regionId→cityId
                    // mapping; fall back to matching the region id against the city id.
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
        var lastError: Error?

        for styleURI in navigationStyles {
            group.enter()
            guard let options = StylePackLoadOptions(
                glyphsRasterizationMode: .ideographsRasterizedLocally,
                metadata: ["name": name, "updatedAt": Date().timeIntervalSince1970]
            ) else {
                lastError = NSError(domain: "OfflineManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create StylePackLoadOptions"])
                group.leave()
                continue
            }

            _ = offlineManager.loadStylePack(for: styleURI, loadOptions: options) { _ in } completion: { result in
                if case .failure(let error) = result {
                    lastError = error
                }
                group.leave()
            }
        }

        group.notify(queue: .main) {
            if let lastError {
                completion(.failure(lastError))
            } else {
                completion(.success(()))
            }
        }
    }
    
    /// The routing dataset must match `RoutingConfig.datasetProfileIdentifier` (walking).
    private static let navigationTilesDataset = ProfileIdentifier.walking.rawValue

    /// Resolves the latest routing-tiles version from Mapbox. Nav SDK 3.20+ broke
    /// `getLatestNavigationTilesetDescriptor()`: it stamps an EMPTY version into the
    /// downloaded region, which the router can never match offline ("not available in
    /// cache"), so the exact version must be resolved and pinned explicitly.
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
            // Versions are "YYYY_MM_DD-HH_MM_SS", so lexicographic order is chronological.
            let latest = response.availableVersions.sorted().last
            if let latest {
                NavigationTilesVersionStore.stored = latest
            }
            return latest
        } catch {
            return nil
        }
    }

    /// Called at app start (before the navigation provider is created) so the very
    /// first session already has a pinned tiles version — otherwise the router of a
    /// fresh install can't route offline until the second launch.
    static func resolveNavigationTilesVersionIfNeeded() async {
        guard NavigationTilesVersionStore.stored == nil,
              NetworkMonitor.shared.isConnected else { return }
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
                // The running navigator stays pinned to the version it started with
                // until the next launch — keep that version's tiles in the region too,
                // so offline routing works both before and after a relaunch.
                let runtimeVersion = NavigationTilesVersionStore.pinnedAtLaunch
                if !runtimeVersion.isEmpty && runtimeVersion != version {
                    navigationDescriptors.append(Self.buildNavigationDescriptor(version: runtimeVersion))
                }
            } else {
                // Fallback: known to produce an empty-version region on SDK 3.20+,
                // but better than downloading no navigation tiles at all.
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
                // Filter for regions that are actually complete
                // In Mapbox common, a region exists in allTileRegions even if it failed or is partial.
                // We could check each region's status but that's async per region.
                // For now, let's just return what they have and let fetchRegionStatus refine it if needed.
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


/// Indirection that silences the deprecation warning on Mapbox's
/// `TilesetDescriptorFactory`. The class is deprecated but remains the only API
/// that can pin an exact routing-tiles version — Mapbox's own SDK still uses it
/// internally, and version pinning is required for offline routing on SDK 3.20+.
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
