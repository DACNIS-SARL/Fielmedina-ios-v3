//
//  MapboxNavigationProviderStore.swift
//  Fielmedina
//
//  Created by Aslan on 1/25/26.
//

import Foundation
import MapboxNavigationCore
import MapboxDirections

/// Persists the routing-tiles version that offline regions are downloaded with.
/// Nav SDK 3.26's router resolves its tiles version from the NETWORK at startup
/// ("Async config init"); offline that fails with NoVersionFound and the on-device
/// router cannot initialize at all — so the version must be pinned in CoreConfig.
enum NavigationTilesVersionStore {
    private static let key = "offline_nav_tiles_version"

    /// The version the running navigator was configured with at creation time.
    static private(set) var pinnedAtLaunch = ""

    static var stored: String? {
        get { UserDefaults.standard.string(forKey: key) }
        set { UserDefaults.standard.set(newValue, forKey: key) }
    }

    static func consumeForLaunch() -> String {
        pinnedAtLaunch = stored ?? ""
        return pinnedAtLaunch
    }
}

enum MapboxNavigationProviderStore {
    static let shared: MapboxNavigationProvider = {
        let routingConfig = RoutingConfig(
            datasetProfileIdentifier: .walking,
            routingProviderSource: .hybrid
        )
        let config = CoreConfig(
            routingConfig: routingConfig,
            locationSource: .live,
            // Pin the routing-tiles version to the one our offline regions carry.
            // Empty string = SDK resolves "latest" from the network, which fails
            // offline (RoutingTilesConfig NoVersionFound) and kills onboard routing.
            tilesVersion: NavigationTilesVersionStore.consumeForLaunch(),
            // Point the navigation engine at the same explicit tile store used for
            // offline region downloads (OfflineTileStore). With the `.default`
            // configuration, Nav SDK 3.20+ resolves a different store than
            // `TileStore.default`, so offline routing never saw the downloaded tiles.
            tilestoreConfig: .custom(OfflineTileStore.tileStoreURL)
        )
        return MapboxNavigationProvider(coreConfig: config)
    }()

    @MainActor
    static func routingProvider() -> RoutingProvider {
        shared.routingProvider()
    }
}
