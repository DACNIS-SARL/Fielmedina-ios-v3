//
//  HikingListModel.swift
//  Fielmedina
//
//  Presentation model for the Hiking Routes list.
//  Follows the reference pattern documented in `AllLocationsModel`.
//
//  This screen is the closest existing analogue to how AR will behave: it drives an
//  expensive, session-backed engine (the Mapbox router) from UI state. Three rules
//  that will carry straight over to an ARSession are applied here:
//
//    1. Bound the concurrency. Firing one engine request per row at once saturates
//       the device and the network.
//    2. Debounce the trigger. Raw GPS updates arrive constantly; recomputing on
//       every tick is wasted work.
//    3. Keep the results in the model, not the View, so they survive view
//       recreation instead of being recomputed on every return to the screen.
//

import Foundation
import CoreLocation
import MapboxDirections
import MapboxNavigationCore
import Observation

@MainActor
@Observable
final class HikingListModel {

    // MARK: - Published state

    private(set) var trails: [Hiking] = []
    /// Route distance/duration per trail id. Held here so returning to the screen
    /// shows the previous values immediately instead of recomputing every route.
    private(set) var metrics: [String: HikingMetrics] = [:]
    private(set) var isLoading = true
    private(set) var errorMessage: String?
    private(set) var isConnected = NetworkMonitor.shared.isConnected

    // MARK: - Configuration

    /// Matches the prefetcher's cached query variant so the list works offline.
    private let trailsLimit: Int32 = 200
    /// Routing is expensive; run a few at a time instead of one request per trail.
    private let maxConcurrentMetricRequests = 3
    /// Fallback walking speed (m/s) when routing is unavailable.
    private let realisticHikingSpeed: Double = 0.83

    // MARK: - Dependencies

    private let hikingService: HikingService

    /// User position, bucketed to ~100 m. Metrics only recompute when the user has
    /// actually moved — not on every GPS tick, which would re-route every trail.
    private var userCoordinate: CLLocationCoordinate2D?
    private var userLocationBucket: String?
    /// Internal plumbing, never rendered — `@ObservationIgnored` keeps it a plain
    /// stored property, and `nonisolated(unsafe)` lets the non-isolated `deinit`
    /// cancel it.
    @ObservationIgnored nonisolated(unsafe) private var metricsTask: Task<Void, Never>?

    /// Internal plumbing, never rendered — `@ObservationIgnored` keeps it a plain
    /// stored property (no observation overhead), and `nonisolated(unsafe)` lets the
    /// non-isolated `deinit` remove the observer. Written once in `init`, read once
    /// in `deinit`, never concurrently.
    @ObservationIgnored nonisolated(unsafe) private var networkObserver: NSObjectProtocol?

    init(hikingService: HikingService = .shared) {
        self.hikingService = hikingService

        networkObserver = NotificationCenter.default.addObserver(
            forName: .networkStatusChanged,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let connected = notification.userInfo?["isConnected"] as? Bool else { return }
            Task { @MainActor [weak self] in
                self?.handleConnectivityChange(connected)
            }
        }
    }

    deinit {
        metricsTask?.cancel()
        if let networkObserver {
            NotificationCenter.default.removeObserver(networkObserver)
        }
    }

    private func handleConnectivityChange(_ connected: Bool) {
        let wasOffline = !isConnected
        isConnected = connected
        if connected && wasOffline {
            Task { await loadTrails() }
        }
    }

    // MARK: - Inputs from the View

    /// Feeds the user's position in. The View owns CoreLocation permission and
    /// lifecycle; the model only needs the coordinate, which keeps it testable.
    func updateUserLocation(_ coordinate: CLLocationCoordinate2D?) {
        userCoordinate = coordinate
        let bucket = coordinate.map { "\(Int($0.latitude * 1000)),\(Int($0.longitude * 1000))" }
        // Only react to real movement — otherwise every GPS jitter re-routes every trail.
        guard bucket != userLocationBucket else { return }
        userLocationBucket = bucket

        sortTrailsByDistanceIfPossible()
        scheduleMetricsUpdate()
    }

    // MARK: - Loading

    func loadTrails() async {
        isLoading = true
        errorMessage = nil
        do {
            trails = try await hikingService.fetchHikings(cityId: nil, limit: trailsLimit)
            sortTrailsByDistanceIfPossible()
            scheduleMetricsUpdate()
        } catch {
            LogUtils.e("HikingListModel", "Failed to load trails: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func refreshFromNetwork() async {
        await loadTrails()
    }

    // MARK: - Metrics

    /// Replaces any in-flight metrics pass, so a burst of movement or reloads never
    /// stacks multiple full route-calculation runs on top of each other.
    private func scheduleMetricsUpdate() {
        metricsTask?.cancel()
        metricsTask = Task { [weak self] in
            await self?.updateMetrics()
        }
    }

    private func updateMetrics() async {
        guard let userCoordinate else { return }
        let trailsSnapshot = trails
        guard !trailsSnapshot.isEmpty else { return }

        var results: [String: HikingMetrics] = [:]

        // Bounded sliding window: at most `maxConcurrentMetricRequests` route
        // calculations in flight, instead of one per trail all at once.
        await withTaskGroup(of: (String, HikingMetrics?).self) { group in
            var index = 0
            let limit = min(trailsSnapshot.count, maxConcurrentMetricRequests)

            while index < limit {
                let trail = trailsSnapshot[index]
                group.addTask { [weak self] in
                    guard let self else { return (trail.id, nil) }
                    return (trail.id, await self.calculateMetrics(for: trail, userCoordinate: userCoordinate))
                }
                index += 1
            }

            while let (id, metric) = await group.next() {
                if let metric { results[id] = metric }

                if Task.isCancelled { break }

                if index < trailsSnapshot.count {
                    let trail = trailsSnapshot[index]
                    group.addTask { [weak self] in
                        guard let self else { return (trail.id, nil) }
                        return (trail.id, await self.calculateMetrics(for: trail, userCoordinate: userCoordinate))
                    }
                    index += 1
                }
            }
        }

        guard !Task.isCancelled else { return }
        // Merge rather than replace, so a cancelled pass never wipes known values.
        metrics.merge(results) { _, new in new }
    }

    private func calculateMetrics(
        for hiking: Hiking,
        userCoordinate: CLLocationCoordinate2D
    ) async -> HikingMetrics? {
        let trailWaypoints = hiking.waypoints.map {
            Waypoint(coordinate: CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude))
        }
        // Sanitize before the router sees it (drops invalid/(0,0)/duplicate points and
        // caps at Mapbox's 25-waypoint limit) so a bad trail can't crash the offline router.
        let waypoints = RouteWaypointSanitizer.sanitize([Waypoint(coordinate: userCoordinate)] + trailWaypoints)

        if waypoints.count >= 2 {
            let options = NavigationRouteOptions(waypoints: waypoints)
            options.profileIdentifier = .walking

            do {
                let routingProvider = MapboxNavigationProviderStore.routingProvider()
                let response = try await routingProvider.calculateRoutes(options: options).value
                let route = response.mainRoute.route
                return HikingMetrics(distance: route.distance, duration: route.expectedTravelTime)
            } catch is CancellationError {
                return nil
            } catch {
                LogUtils.w("HikingListModel", "Routing failed, using manual fallback: \(error.localizedDescription)")
            }
        }

        // Fallback: use the trail's own distance when routing is unavailable.
        if let totalDistance = hiking.totalDistance {
            let distanceInMeters = totalDistance * 1000
            return HikingMetrics(
                distance: distanceInMeters,
                duration: distanceInMeters / realisticHikingSpeed
            )
        }
        return nil
    }

    // MARK: - Sorting

    private func sortTrailsByDistanceIfPossible() {
        guard let userCoordinate else { return }
        let userLocation = CLLocation(latitude: userCoordinate.latitude, longitude: userCoordinate.longitude)
        // Distances computed once per trail rather than twice per comparison.
        trails = trails
            .map { trail -> (trail: Hiking, distance: CLLocationDistance) in
                let candidate = CLLocation(latitude: trail.latitude, longitude: trail.longitude)
                return (trail, candidate.distance(from: userLocation))
            }
            .sorted { $0.distance < $1.distance }
            .map(\.trail)
    }
}
