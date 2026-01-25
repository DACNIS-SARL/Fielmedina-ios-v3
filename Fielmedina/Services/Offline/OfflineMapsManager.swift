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

final class OfflineMapsManager {
    static let shared = OfflineMapsManager()

    private let offlineManager = OfflineManager()
    private let tileStore = TileStore.default

    private init() {
        // NSNull() is used to indicate "no limit" for the disk quota
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
        let styleURI: StyleURI = .standard
        
        // FIX: Explicitly unwrap or handle the failable initializer
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
                progress(min(completed / required, 1) * 0.2) // Style pack is ~20% of the work
            }
        } completion: { [weak self] result in
            switch result {
            case .failure(let error):
                DispatchQueue.main.async { completion(.failure(error)) }
            case .success:
                self?.downloadTiles(
                    id: id,
                    coordinate: coordinate,
                    radius: radius,
                    progress: progress,
                    completion: completion
                )
            }
        }
    }

    private func downloadTiles(
        id: String,
        coordinate: CLLocationCoordinate2D,
        radius: CLLocationDistance,
        progress: @escaping (Double) -> Void,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        let styleOptions = TilesetDescriptorOptions(
            styleURI: .standard,
            zoomRange: 11...16, tilesets: nil
        )
        let descriptor = offlineManager.createTilesetDescriptor(for: styleOptions)

        let geometry = Geometry(Polygon(center: coordinate, radiusMeters: radius))
        
        // FIX: TileRegionLoadOptions returns an optional. We must unwrap it.
        guard let loadOptions = TileRegionLoadOptions(
            geometry: geometry,
            descriptors: [descriptor],
            metadata: ["name": id],
            acceptExpired: true
        ) else {
            completion(.failure(NSError(domain: "OfflineManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create TileRegionLoadOptions"])))
            return
        }

        tileStore.loadTileRegion(
            forId: id,
            loadOptions: loadOptions
        ) { tileProgress in
            DispatchQueue.main.async {
                let completed = Double(tileProgress.completedResourceCount)
                let required = max(Double(tileProgress.requiredResourceCount), 1)
                // Combine with style pack progress: 0.2 + (0.8 * progress)
                let currentProgress = 0.2 + (min(completed / required, 1) * 0.8)
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
        // Note: Removing style pack might affect other regions.
        // Usually, we just remove the Tile Region.
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
}

// Helper to create a polygon for the download area
private extension Polygon {
    init(center: CLLocationCoordinate2D, radiusMeters: CLLocationDistance) {
        let region = MKCoordinateRegion(center: center, latitudinalMeters: radiusMeters * 2, longitudinalMeters: radiusMeters * 2)
        
        let latDelta = region.span.latitudeDelta / 2
        let lonDelta = region.span.longitudeDelta / 2
        
        let topLeft = CLLocationCoordinate2D(latitude: center.latitude + latDelta, longitude: center.longitude - lonDelta)
        let topRight = CLLocationCoordinate2D(latitude: center.latitude + latDelta, longitude: center.longitude + lonDelta)
        let bottomRight = CLLocationCoordinate2D(latitude: center.latitude - latDelta, longitude: center.longitude + lonDelta)
        let bottomLeft = CLLocationCoordinate2D(latitude: center.latitude - latDelta, longitude: center.longitude - lonDelta)

        self.init([[topLeft, topRight, bottomRight, bottomLeft, topLeft]])
    }
}
