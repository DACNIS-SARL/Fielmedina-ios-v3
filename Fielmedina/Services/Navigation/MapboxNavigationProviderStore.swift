//
//  MapboxNavigationProviderStore.swift
//  Fielmedina
//
//  Created by Aslan on 1/25/26.
//

import Foundation
import MapboxNavigationCore
import MapboxDirections

enum MapboxNavigationProviderStore {
    /// Same path used by OfflineTileStore / MapboxMapsOptions.dataPath
    /// so the Navigation SDK reads tiles from the same directory
    /// where OfflineMapsManager downloads them.
    private static let tilesURL: URL = {
        let base = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let url = base.appendingPathComponent("mapbox-tiles", isDirectory: true)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }()

    static let shared: MapboxNavigationProvider = {
        let routingConfig = RoutingConfig(
            datasetProfileIdentifier: .walking,
            routingProviderSource: .hybrid
        )
        let config = CoreConfig(
            routingConfig: routingConfig,
            locationSource: .live,
            tilestoreConfig: .custom(tilesURL)
        )
        return MapboxNavigationProvider(coreConfig: config)
    }()

    @MainActor
    static func routingProvider() -> RoutingProvider {
        shared.routingProvider()
    }
}

