//
//  OfflineTileStore.swift
//  Fielmedina
//
//  Created by Aslan on 11/6/2026.
//

import Foundation
import MapboxCommon
import MapboxMaps

enum OfflineTileStore {
    /// Explicit tile store location shared by map rendering, offline region downloads,
    /// and the navigation engine. Nav SDK 3.20+ resolves its *default* store location
    /// differently from `TileStore.default` (empty path → process working directory),
    /// which silently split downloads and offline routing into different stores and
    /// broke offline navigation. Pinning one explicit path keeps every consumer unified.
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
        clearOldCacheIfNecessary()
        migrateToExplicitTileStorePathIfNeeded()
        MapboxMapsOptions.tileStore = shared
        MapboxMapsOptions.tileStoreUsageMode = .readAndUpdate
    }

    /// One-time reset when switching to the explicit FielmedinaTiles store location.
    /// Regions downloaded by builds that used the SDK-default store location are not
    /// visible in the explicit store, so the "downloaded" flags would lie — reset them
    /// and re-run onboarding so the user is guided to re-download, and delete the old
    /// store to free disk space.
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

    private static func clearOldCacheIfNecessary() {
        let mapboxBundle = Bundle(for: TileStore.self)
        let currentMapboxVersion = mapboxBundle.infoDictionary?["CFBundleShortVersionString"] as? String ?? "24.19.0"
        let migrationKey = "lastClearedMapCacheForMapboxVersion"
        
        let storedMapboxVersion = UserDefaults.standard.string(forKey: migrationKey) ?? ""
        if storedMapboxVersion != currentMapboxVersion {
            let fileManager = FileManager.default
            if let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
                let mapboxPaths = [".mapbox", "mapbox", "mapbox-tiles", "FielmedinaTiles"]
                for path in mapboxPaths {
                    let url = appSupportURL.appendingPathComponent(path)
                    try? fileManager.removeItem(at: url)
                }
            }
            if let cachesURL = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first {
                let cachePaths = ["mapbox", "com.mapbox.common"]
                for path in cachePaths {
                    let url = cachesURL.appendingPathComponent(path)
                    try? fileManager.removeItem(at: url)
                }
            }
            OfflineCityDataStore.shared.downloadedCityIds = []
            UserDefaults.standard.removeObject(forKey: "offline_city_region_map")
            UserDefaults.standard.removeObject(forKey: "offline_cities_metadata_cache")
            UserDefaults.standard.set(false, forKey: "hasSeenOnboarding")
            UserDefaults.standard.set(currentMapboxVersion, forKey: migrationKey)
        }
    }
}
