//
//  MapboxNavigationProviderStore.swift
//  Fielmedina
//
//  Created by Aslan on 1/25/26.
//

import Foundation
import CoreLocation
import MapboxNavigationCore
import MapboxDirections

/// Cleans a waypoint list before it reaches the offline onboard router. Malformed
/// input — invalid or (0,0) coordinates, consecutive duplicates, or more than
/// Mapbox's 25-coordinate limit — can make Nav SDK 3.26's native onboard router fail
/// hard (crash) instead of returning an error. This keeps every request in safe bounds.
enum RouteWaypointSanitizer {
    /// Mapbox Directions allows at most 25 coordinates per request.
    static let maxWaypoints = 25

    static func sanitize(_ waypoints: [Waypoint]) -> [Waypoint] {
        // 1) Valid coordinates only. (0,0) is "valid" per CoreLocation but almost
        //    always means an unset/missing point, so drop it too.
        let valid = waypoints.filter { wp in
            let c = wp.coordinate
            return CLLocationCoordinate2DIsValid(c) && !(c.latitude == 0 && c.longitude == 0)
        }

        // 2) Drop consecutive near-duplicates (~0.1 m); they add nothing and can
        //    confuse the router.
        var deduped: [Waypoint] = []
        for wp in valid {
            if let last = deduped.last {
                let dLat = abs(last.coordinate.latitude - wp.coordinate.latitude)
                let dLon = abs(last.coordinate.longitude - wp.coordinate.longitude)
                if dLat < 1e-6 && dLon < 1e-6 { continue }
            }
            deduped.append(wp)
        }

        // 3) Cap to the 25-coordinate limit, always keeping the first (start) and
        //    last (destination) and evenly subsampling the middle.
        guard deduped.count > maxWaypoints,
              let first = deduped.first,
              let last = deduped.last else {
            return deduped
        }
        let middle = Array(deduped.dropFirst().dropLast())
        let slots = maxWaypoints - 2
        var result: [Waypoint] = [first]
        if slots > 0 && !middle.isEmpty {
            let step = Double(middle.count) / Double(slots)
            for i in 0..<slots {
                let idx = min(Int((Double(i) + 0.5) * step), middle.count - 1)
                let candidate = middle[idx]
                let prev = result.last!.coordinate
                if prev.latitude != candidate.coordinate.latitude
                    || prev.longitude != candidate.coordinate.longitude {
                    result.append(candidate)
                }
            }
        }
        result.append(last)
        return result
    }
}

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
