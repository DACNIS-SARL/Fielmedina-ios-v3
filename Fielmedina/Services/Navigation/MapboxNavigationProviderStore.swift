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
    static let shared: MapboxNavigationProvider = {
        let routingConfig = RoutingConfig(
            datasetProfileIdentifier: .walking,
            routingProviderSource: .hybrid
           
        )
        let config = CoreConfig(
            routingConfig: routingConfig,
            locationSource: .live
        )
        return MapboxNavigationProvider(coreConfig: config)
    }()

    @MainActor
    static func routingProvider() -> RoutingProvider {
        shared.routingProvider()
    }
}
