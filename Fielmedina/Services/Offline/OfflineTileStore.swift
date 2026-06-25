//
//  OfflineTileStore.swift
//  Fielmedina
//
//  Created by Aslan on 11/6/2026.
//

import MapboxCommon
import MapboxMaps

enum OfflineTileStore {
    static let shared: TileStore = {
        let store = TileStore.default
        store.setOptionForKey(TileStoreOptions.diskQuota, value: NSNull())
        return store
    }()

    static func configure() {
        clearOldCacheIfNecessary()
        MapboxMapsOptions.tileStore = shared
        MapboxMapsOptions.tileStoreUsageMode = .readAndUpdate
    }

    private static func clearOldCacheIfNecessary() {
        let mapboxBundle = Bundle(for: TileStore.self)
        let currentMapboxVersion = mapboxBundle.infoDictionary?["CFBundleShortVersionString"] as? String ?? "24.19.0"
        let migrationKey = "lastClearedMapCacheForMapboxVersion"
        
        let storedMapboxVersion = UserDefaults.standard.string(forKey: migrationKey) ?? ""
        if storedMapboxVersion != currentMapboxVersion {
            let fileManager = FileManager.default
            if let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
                let mapboxPaths = [".mapbox", "mapbox", "mapbox-tiles"]
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
