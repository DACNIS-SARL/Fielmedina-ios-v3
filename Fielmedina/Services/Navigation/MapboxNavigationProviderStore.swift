//
//  MapboxNavigationProviderStore.swift
//  Fielmedina
//
//  Created by Aslan on 1/25/26.
//

import Foundation
import MapboxNavigationCore

enum MapboxNavigationProviderStore {
    static let shared: MapboxNavigationProvider = {
        let config = CoreConfig(locationSource: .live)
        return MapboxNavigationProvider(coreConfig: config)
    }()
}

