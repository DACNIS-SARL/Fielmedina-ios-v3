import Foundation
import CoreLocation
import MapboxNavigationCore
import MapboxDirections

enum RouteWaypointSanitizer {
    static let maxWaypoints = 25

    static func sanitize(_ waypoints: [Waypoint]) -> [Waypoint] {
        let valid = waypoints.filter { wp in
            let c = wp.coordinate
            return CLLocationCoordinate2DIsValid(c) && !(c.latitude == 0 && c.longitude == 0)
        }

        var deduped: [Waypoint] = []
        for wp in valid {
            if let last = deduped.last {
                let dLat = abs(last.coordinate.latitude - wp.coordinate.latitude)
                let dLon = abs(last.coordinate.longitude - wp.coordinate.longitude)
                if dLat < 1e-6 && dLon < 1e-6 { continue }
            }
            deduped.append(wp)
        }

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

enum NavigationTilesVersionStore {
    private static let key = "offline_nav_tiles_version"
    private static let regionVersionsKey = "offline_nav_region_versions"

    static private(set) var pinnedAtLaunch = ""

    static var stored: String? {
        get { UserDefaults.standard.string(forKey: key) }
        set { UserDefaults.standard.set(newValue, forKey: key) }
    }

    static var regionVersions: [String: [String]] {
        get { UserDefaults.standard.dictionary(forKey: regionVersionsKey) as? [String: [String]] ?? [:] }
        set { UserDefaults.standard.set(newValue, forKey: regionVersionsKey) }
    }

    static func consumeForLaunch() -> String {
        pinnedAtLaunch = stored ?? ""
        return pinnedAtLaunch
    }

    static func versionsForDownload(available: [String]?) -> [String] {
        var versions: [String] = []
        for candidate in [available?.last, stored, pinnedAtLaunch] {
            guard let candidate, !candidate.isEmpty, !versions.contains(candidate) else { continue }
            if let available, !available.contains(candidate) { continue }
            versions.append(candidate)
        }
        return versions
    }

    static func beginDownload(regionId: String, versions: [String]) {
        var records = regionVersions
        guard let current = records[regionId] else { return }
        records[regionId] = current.filter(versions.contains)
        regionVersions = records
    }

    static func completeDownload(regionId: String, versions: [String]) {
        guard !versions.isEmpty else { return }
        var records = regionVersions
        records[regionId] = versions
        regionVersions = records
    }

    static func forget(regionId: String) {
        var records = regionVersions
        records.removeValue(forKey: regionId)
        regionVersions = records
    }

    static func hasPinnedVersion(regionId: String) -> Bool {
        guard let stored, !stored.isEmpty else { return false }
        return regionVersions[regionId]?.contains(stored) ?? false
    }

    static func pinToNewestCommonVersion(regionIds: [String]) {
        let records = regionVersions
        var common: Set<String>?
        for regionId in regionIds {
            let versions = Set(records[regionId] ?? [])
            common = common.map { $0.intersection(versions) } ?? versions
        }
        guard let newest = common?.max() else { return }
        stored = newest
    }
}

enum MapboxNavigationProviderStore {
    @MainActor
    static let shared: MapboxNavigationProvider = {
        let routingConfig = RoutingConfig(
            datasetProfileIdentifier: .walking,
            routingProviderSource: .hybrid
        )
        let config = CoreConfig(
            routingConfig: routingConfig,
            locationSource: .live,
            tilesVersion: NavigationTilesVersionStore.consumeForLaunch(),
            tilestoreConfig: .custom(OfflineTileStore.tileStoreURL)
        )
        let provider = MapboxNavigationProvider(coreConfig: config)
        _ = provider.getLatestNavigationTilesetDescriptor()
        return provider
    }()

    @MainActor
    static func routingProvider() -> RoutingProvider {
        shared.routingProvider()
    }
}
