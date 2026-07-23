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

    private init() { }

//    private init() {
//        tileStore.setOptionForKey(TileStoreOptions.diskQuota, value: NSNull())
//    }

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

    /// Re-downloads every existing tile region (incremental — only changed resources are
    /// fetched) so the offline navigation tiles stay pinned to a routing-tiles version the
    /// navigator can still use. Without this, the navigator's "latest" version drifts ahead
    /// of the downloaded region over time and offline routing eventually fails until the
    /// user manually deletes and re-downloads the map.
    func refreshDownloadedRegionsIfNeeded() {
        guard NetworkMonitor.shared.isConnected else { return }

        let defaults = UserDefaults.standard
        if let last = defaults.object(forKey: Self.lastRegionRefreshKey) as? Date,
           Date().timeIntervalSince(last) < Self.regionRefreshInterval {
            return
        }

        fetchDownloadedRegionIds { [weak self] regionIds in
            guard let self else { return }
            defaults.set(Date(), forKey: Self.lastRegionRefreshKey)
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

                self.downloadRegion(
                    id: regionId,
                    name: city.name,
                    coordinate: CLLocationCoordinate2D(latitude: city.latitude, longitude: city.longitude),
                    radius: city.radius,
                    silent: true,
                    progress: { _ in },
                    completion: { _ in }
                )
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
    
    private func downloadNavigationTiles(
        id: String,
        coordinate: CLLocationCoordinate2D,
        radius: CLLocationDistance,
        silent: Bool = false,
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
        let navigationDescriptor = MapboxNavigationProviderStore.shared.getLatestNavigationTilesetDescriptor()
        
        let geometry = Geometry.polygon(Polygon(center: coordinate, radiusMeters: radius))
        
        let descriptors = tilesetDescriptors + [navigationDescriptor]

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
