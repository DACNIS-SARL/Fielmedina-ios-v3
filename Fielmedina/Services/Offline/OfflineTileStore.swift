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

    /// Call ONCE at launch, before any MapView, navigation provider,
    /// or OfflineManager is created.
    static func configure() {
        // Bind the Maps SDK (and therefore Nav, which shares it) to our store.
        MapboxMapsOptions.tileStore = shared
        MapboxMapsOptions.tileStoreUsageMode = .readAndUpdate
    }
}
