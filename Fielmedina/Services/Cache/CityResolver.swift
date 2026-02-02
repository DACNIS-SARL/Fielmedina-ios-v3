//
//  CityResolver.swift
//  Fielmedina
//
//  Created by Aslan on 2/2/26.
//

import Foundation
import CoreLocation

actor CityResolver {
    static let shared = CityResolver()

    private var lastResolvedLocation: CLLocation?
    private var lastResolvedAt: Date?

    private let minimumDistance: CLLocationDistance = 5_000
    private let minimumInterval: TimeInterval = 5 * 60

    func handleLocationUpdate(_ location: CLLocation) async {
        let hasStoredCity = CitySelectionStore.shared.cityId != nil
        if shouldSkipResolution(location: location, hasStoredCity: hasStoredCity) {
            return
        }

        lastResolvedLocation = location
        lastResolvedAt = Date()

        do {
            let query = FielmedinaAPI.GetNearestCityQuery(
                lat: location.coordinate.latitude,
                lon: location.coordinate.longitude
            )
            let data = try await Network.shared.apollo.fetchNetworkAware(query: query)
            if let cityIdString = data.nearestCity?.id,
               let cityId = Int32(cityIdString) {
                let previousCityId = CitySelectionStore.shared.cityId
                guard previousCityId != cityId else { return }
                CitySelectionStore.shared.cityId = cityId

                await MainActor.run {
                    NotificationCenter.default.post(name: .cityDidChange, object: cityId)
                }

                await MainActor.run {
                    guard !NetworkMonitor.shared.isConnected else { return }
                    if !OfflineCityDataStore.shared.hasCityData(cityId: cityId) {
                        NotificationCenter.default.post(name: .offlineCityDataMissing, object: cityId)
                    }
                }
            }
        } catch {
            return
        }
    }

    private func shouldSkipResolution(location: CLLocation, hasStoredCity: Bool) -> Bool {
        guard let lastLocation = lastResolvedLocation,
              let lastResolvedAt else {
            return hasStoredCity
        }

        if Date().timeIntervalSince(lastResolvedAt) < minimumInterval,
           location.distance(from: lastLocation) < minimumDistance {
            return hasStoredCity
        }

        return false
    }
}

extension Notification.Name {
    static let cityDidChange = Notification.Name("city_did_change")
    static let offlineCityDataMissing = Notification.Name("offline_city_data_missing")
}
