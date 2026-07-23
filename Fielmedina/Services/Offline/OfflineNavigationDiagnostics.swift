//
//  OfflineNavigationDiagnostics.swift
//  Fielmedina
//

import CoreLocation
import Foundation

/// Explains offline navigation failures precisely. The on-device router can only
/// build a route when BOTH the user's position and the destination lie inside a
/// downloaded region, so a generic "navigation failed" hides the actual cause
/// (most commonly: the user is standing outside the downloaded circle).
@MainActor
enum OfflineNavigationDiagnostics {

    static func failureMessage(for error: Error) -> String {
        let generic = String(localized: "Navigation failed. If you are offline, please ensure you have downloaded the maps for this area.")
            + "\n\n"
            + String(localized: "Error: \(error.localizedDescription)")

        guard !NetworkMonitor.shared.isConnected else {
            return generic
        }

        let store = OfflineCityDataStore.shared
        let downloadedIds = store.downloadedCityIds
        let downloadedCities = store.cachedCities.filter { downloadedIds.contains($0.cityId) }

        guard !downloadedCities.isEmpty else {
            return String(localized: "You are offline and no offline maps are downloaded. Open Settings and download your city to navigate offline.")
        }

        guard let coordinate = LocationManager.shared.userLocation else {
            return generic
        }

        let user = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        var nearestName = downloadedCities[0].name
        var smallestGap = Double.greatestFiniteMagnitude
        for city in downloadedCities {
            let center = CLLocation(latitude: city.latitude, longitude: city.longitude)
            let gap = user.distance(from: center) - city.radius
            if gap <= 0 {
                // Inside a downloaded region — the failure is not a coverage problem.
                return generic
            }
            if gap < smallestGap {
                smallestGap = gap
                nearestName = city.name
            }
        }

        let kilometers = smallestGap / 1000
        return String(
            format: String(localized: "You are offline and %.1f km outside the downloaded \"%@\" map area. Offline navigation only works inside downloaded areas."),
            kilometers,
            nearestName
        )
    }
}
