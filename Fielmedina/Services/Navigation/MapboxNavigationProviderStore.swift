//
//  MapboxNavigationProviderStore.swift
//  Fielmedina
//
//  Created by Aslan on 1/25/26.
//

import Foundation
import MapboxNavigationCore

/// Singleton store for the Mapbox Navigation provider.
/// Configured with live location source for optimal navigation performance.
/// Initialization is triggered at app launch for faster navigation startup.
enum MapboxNavigationProviderStore {
    static let shared: MapboxNavigationProvider = {
        let config = CoreConfig(locationSource: .live)
        return MapboxNavigationProvider(coreConfig: config)
    }()
}

