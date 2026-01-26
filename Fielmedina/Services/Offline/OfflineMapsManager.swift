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

final class OfflineMapsManager {
    static let shared = OfflineMapsManager()
    
    private let offlineManager = OfflineManager()
    private var tileStore: TileStore {
        TileStore.default
    }
    
    private init() {
        tileStore.setOptionForKey(TileStoreOptions.diskQuota, value: NSNull())
    }
    
    func downloadRegion(
        id: String,
        name: String,
        coordinate: CLLocationCoordinate2D,
        radius: CLLocationDistance,
        progress: @escaping (Double) -> Void,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        
        downloadStylePack(name: name, progress: progress) { [weak self] result in
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success:
                self?.downloadNavigationTiles(
                    id: id,
                    coordinate: coordinate,
                    radius: radius,
                    progress: progress,
                    completion: completion
                )
            }
        }
    }
    
    private func downloadStylePack(
        name: String,
        progress: @escaping (Double) -> Void,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        let styleURI: StyleURI = .standard
        
        guard let stylePackLoadOptions = StylePackLoadOptions(
            glyphsRasterizationMode: .ideographsRasterizedLocally,
            metadata: ["name": name]
        ) else {
            completion(.failure(NSError(domain: "OfflineManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create StylePackLoadOptions"])))
            return
        }
        
        _ = offlineManager.loadStylePack(
            for: styleURI,
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
                    completion(.success(()))
                }
            }
        }
    }
    
    private func downloadNavigationTiles(
        id: String,
        coordinate: CLLocationCoordinate2D,
        radius: CLLocationDistance,
        progress: @escaping (Double) -> Void,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        let styleURI: StyleURI = .standard
        let zoomRange: ClosedRange<UInt8> = 0...16
        
        let tilesetDescriptorOptions = TilesetDescriptorOptions(
            styleURI: styleURI,
            zoomRange: zoomRange,
            tilesets: nil
        )
        
        let tilesetDescriptor = offlineManager.createTilesetDescriptor(for: tilesetDescriptorOptions)
        let navigationDescriptor = MapboxNavigationProviderStore.shared.getLatestNavigationTilesetDescriptor()
        
        let geometry = Geometry.polygon(Polygon(center: coordinate, radiusMeters: radius))
        
        guard let tileRegionLoadOptions = TileRegionLoadOptions(
            geometry: geometry,
            descriptors: [tilesetDescriptor, navigationDescriptor],
            metadata: ["name": id],
            acceptExpired: true
        ) else {
            completion(.failure(NSError(domain: "OfflineManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create TileRegionLoadOptions"])))
            return
        }
        
        tileStore.loadTileRegion(
            forId: id,
            loadOptions: tileRegionLoadOptions
        ) { tileProgress in
            DispatchQueue.main.async {
                let completed = Double(tileProgress.completedResourceCount)
                let required = max(Double(tileProgress.requiredResourceCount), 1)
                let currentProgress = 0.15 + (min(completed / required, 1) * 0.85)
                progress(currentProgress)
            }
        } completion: { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    completion(.success(()))
                case .failure(let error):
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
