//
//  PlaceNavigationModel.swift
//  Fielmedina
//
//  Shared "navigate me to this place" model, used by the Location and Merchant
//  detail screens. Both previously carried a near-identical copy of this logic
//  (~50 duplicated lines each, which had already drifted apart).
//
//  Follows the reference pattern documented in `AllLocationsModel`. This is also the
//  closest template for launching an AR session from a detail screen: a user action
//  starts an expensive engine, the engine reports readiness asynchronously, and every
//  failure path has to surface a specific, localized message.
//

import Foundation
import CoreLocation
import MapboxDirections
import MapboxNavigationCore
import Observation

@MainActor
@Observable
final class PlaceNavigationModel {

    /// Calculated routes handed to the navigation UI. Settable so the cover view can
    /// clear it on dismissal.
    var routes: NavigationRoutes?
    /// Drives the full-screen navigation cover.
    var isPresented = false
    /// True until Mapbox reports the map is ready to draw.
    var isLoading = false

    // Alert flags (bound directly by the Views).
    var showLocationPermissionAlert = false
    var showErrorAlert = false
    var showDownloadRequiredAlert = false

    private(set) var errorMessage = ""
    /// City the user must download before offline navigation can start.
    private(set) var missingCityName = ""

    /// Starts turn-by-turn navigation to `destination`.
    ///
    /// - Parameters:
    ///   - destination: nil when the place has no coordinates on record.
    ///   - userCoordinate: nil when location permission hasn't been granted.
    ///   - missingDestinationMessage: shown when `destination` is nil, so each screen
    ///     can phrase it for its own content type.
    ///   - placeId / placeType: identify the destination for the Meta conversion
    ///     event. Required rather than defaulted so a new caller cannot silently
    ///     ship without attribution data.
    func start(
        to destination: CLLocationCoordinate2D?,
        from userCoordinate: CLLocationCoordinate2D?,
        missingDestinationMessage: String,
        placeId: String,
        placeType: String
    ) {
        guard let userCoordinate else {
            showLocationPermissionAlert = true
            return
        }

        guard let destination else {
            errorMessage = missingDestinationMessage
            showErrorAlert = true
            return
        }

        // Offline: refuse early with a clear message if this city's map isn't downloaded,
        // rather than letting the router fail with something opaque.
        if !NetworkMonitor.shared.isConnected {
            let cityId = OfflineCityDataStore.shared.getCityId(for: destination)
            if !OfflineCityDataStore.shared.hasCityData(cityId: cityId) {
                missingCityName = OfflineCityDataStore.shared.getCityName(for: cityId)
                showDownloadRequiredAlert = true
                return
            }
        }

        // Logged after every guard has passed, so it counts intent that actually
        // resulted in navigation rather than a blocked tap.
        MetaEvents.logNavigationStarted(placeId: placeId, placeType: placeType)

        isLoading = true
        isPresented = true

        let origin = CLLocationCoordinate2D(
            latitude: userCoordinate.latitude,
            longitude: userCoordinate.longitude
        )
        let options = NavigationRouteOptions(coordinates: [origin, destination])
        options.profileIdentifier = .walking

        Task { [weak self] in
            do {
                let routingProvider = MapboxNavigationProviderStore.routingProvider()
                let response = try await routingProvider.calculateRoutes(options: options).value
                // `isLoading` stays true until the cover view reports the map is ready.
                self?.routes = response
            } catch is CancellationError {
                self?.reset()
            } catch {
                guard let self else { return }
                self.errorMessage = OfflineNavigationDiagnostics.failureMessage(for: error)
                self.showErrorAlert = true
                self.reset()
            }
        }
    }

    /// Clears navigation state — used on dismissal and on failure.
    func reset() {
        routes = nil
        isPresented = false
        isLoading = false
    }
}
