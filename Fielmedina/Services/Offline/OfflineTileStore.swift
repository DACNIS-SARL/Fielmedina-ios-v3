import Foundation
import MapboxCommon
import MapboxMaps

enum OfflineTileStore {
    static let tileStoreURL: URL = {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        var url = base.appendingPathComponent("FielmedinaTiles", isDirectory: true)
        if !FileManager.default.fileExists(atPath: url.path) {
            try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
            var values = URLResourceValues()
            values.isExcludedFromBackup = true
            try? url.setResourceValues(values)
        }
        return url
    }()

    static let shared: TileStore = {
        let store = TileStore.shared(for: tileStoreURL)
        store.setOptionForKey(TileStoreOptions.diskQuota, value: NSNull())
        return store
    }()

    static func configure() {
        migrateToExplicitTileStorePathIfNeeded()
        refreshRegionsAfterMapboxUpdateIfNeeded()
        MapboxMapsOptions.tileStore = shared
        MapboxMapsOptions.tileStoreUsageMode = .readAndUpdate
    }

    private static func migrateToExplicitTileStorePathIfNeeded() {
        let migrationKey = "hasMigratedToExplicitTileStorePath"
        guard !UserDefaults.standard.bool(forKey: migrationKey) else { return }

        let fileManager = FileManager.default
        if let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            for legacyStorePath in [".mapbox", "mapbox"] {
                try? fileManager.removeItem(at: appSupportURL.appendingPathComponent(legacyStorePath))
            }
        }

        OfflineCityDataStore.shared.downloadedCityIds = []
        UserDefaults.standard.removeObject(forKey: "offline_city_region_map")
        UserDefaults.standard.set(false, forKey: "hasSeenOnboarding")
        UserDefaults.standard.set(true, forKey: migrationKey)
    }

    private static func refreshRegionsAfterMapboxUpdateIfNeeded() {
        let versionKey = "offline_maps_mapbox_version"
        let currentVersion = Bundle(for: TileStore.self).infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        guard UserDefaults.standard.string(forKey: versionKey) != currentVersion else { return }
        OfflineMapsManager.markRegionRefreshDue()
        UserDefaults.standard.set(currentVersion, forKey: versionKey)
    }
}
