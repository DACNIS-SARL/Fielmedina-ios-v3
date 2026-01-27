//
//  OfflineContentPrefetcher.swift
//  Fielmedina
//
//  Created by Aslan on 1/26/26.
//

import Foundation
import CoreLocation
import Apollo

@MainActor
final class OfflineContentPrefetcher {
    static let shared = OfflineContentPrefetcher()

    private let completionKey = "offline_prefetch_completed"
    private let statusKey = "offline_prefetch_status"
    private var isRunning = false
    private var isObservingLocation = false
    private var retryTask: Task<Void, Never>?

    enum Status: String {
        case idle
        case downloading
        case waitingForLocation
        case permissionDenied
        case failed
        case completed
    }

    private enum CityResolutionResult {
        case success(Int32)
        case missingLocation
        case permissionDenied
        case failed
    }

    var isComplete: Bool {
        UserDefaults.standard.bool(forKey: completionKey)
    }

    var status: Status {
        if isComplete {
            return .completed
        }
        if let rawValue = UserDefaults.standard.string(forKey: statusKey),
           let storedStatus = Status(rawValue: rawValue) {
            return storedStatus
        }
        return .idle
    }

    func markNeedsRefresh() {
        UserDefaults.standard.set(false, forKey: completionKey)
        updateStatus(.idle)
    }

    func prefetchIfNeeded() {
        guard !isRunning, !isComplete else { return }
        isRunning = true
        updateStatus(.downloading)

        Task {
            let didComplete = await runPrefetch()
            isRunning = false
            if !didComplete {
                handleFailedPrefetch()
            }
        }
    }

    private func runPrefetch() async -> Bool {
        switch await resolveCityIdIfPossible() {
        case .success(let cityId):
            await withTaskGroup(of: Void.self) { group in
                group.addTask { await self.prefetchLocations(cityId: cityId) }
                group.addTask { await self.prefetchEvents(cityId: cityId) }
                group.addTask { await self.prefetchHiking(cityId: cityId) }
                group.addTask { await self.prefetchTransports(cityId: cityId) }
                group.addTask { await self.prefetchTips(cityId: cityId) }
                group.addTask { await self.prefetchAds(cityId: cityId) }
            }

            UserDefaults.standard.set(true, forKey: completionKey)
            updateStatus(.completed)
            NotificationCenter.default.post(name: .offlinePrefetchCompleted, object: nil)
            return true
        case .missingLocation:
            updateStatus(.waitingForLocation)
            return false
        case .permissionDenied:
            updateStatus(.permissionDenied)
            return false
        case .failed:
            updateStatus(.failed)
            return false
        }
    }

    private func resolveCityIdIfPossible() async -> CityResolutionResult {
        if let storedId = CitySelectionStore.shared.cityId {
            return .success(storedId)
        }

        LocationManager.shared.requestPermission()
        LocationManager.shared.startUpdatingLocation()

        if LocationManager.shared.authorizationStatus == .denied
            || LocationManager.shared.authorizationStatus == .restricted {
            return .permissionDenied
        }

        var coordinate: CLLocationCoordinate2D?
        for _ in 0..<10 {
            if let currentCoordinate = LocationManager.shared.userLocation {
                coordinate = currentCoordinate
                break
            }
            try? await Task.sleep(for: .seconds(1))
        }

        guard let coordinate else { return .missingLocation }

        do {
            let query = FielmedinaAPI.GetNearestCityQuery(
                lat: coordinate.latitude,
                lon: coordinate.longitude
            )
            let response = try await Network.shared.apollo.fetch(query: query)
            if let cityIdString = response.data?.nearestCity?.id,
               let cityId = Int32(cityIdString) {
                CitySelectionStore.shared.cityId = cityId
                return .success(cityId)
            }
        } catch {
            return .failed
        }

        return .failed
    }

    private func handleFailedPrefetch() {
        switch status {
        case .waitingForLocation, .permissionDenied:
            observeLocationUpdates()
        case .failed:
            scheduleRetry(after: .seconds(60))
        case .idle, .downloading, .completed:
            break
        }
    }

    private func observeLocationUpdates() {
        guard !isObservingLocation else { return }
        isObservingLocation = true
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleLocationUpdateNotification(_:)),
            name: .locationDidUpdate,
            object: nil
        )
    }

    @objc private func handleLocationUpdateNotification(_ notification: Notification) {
        NotificationCenter.default.removeObserver(self, name: .locationDidUpdate, object: nil)
        isObservingLocation = false
        prefetchIfNeeded()
    }

    private func scheduleRetry(after delay: Duration) {
        retryTask?.cancel()
        retryTask = Task { [weak self] in
            try? await Task.sleep(for: delay)
            await MainActor.run {
                self?.prefetchIfNeeded()
            }
        }
    }

    private func updateStatus(_ status: Status) {
        UserDefaults.standard.set(status.rawValue, forKey: statusKey)
        NotificationCenter.default.post(name: .offlinePrefetchStatusChanged, object: status)
    }

    private func prefetchLocations(cityId: Int32) async {
        do {
            let locations = try await LocationService.shared.fetchLocations(cityId: cityId, limit: 500)
            await ImagePrefetcher.prefetch(from: locations.flatMap { $0.images ?? [] })
        } catch {
            return
        }
    }

    private func prefetchEvents(cityId: Int32) async {
        do {
            let events = try await EventService.shared.fetchEvents(cityId: cityId, limit: 200)
            await ImagePrefetcher.prefetch(from: events.flatMap { $0.images ?? [] })
        } catch {
            return
        }
    }

    private func prefetchHiking(cityId: Int32) async {
        do {
            let trails = try await HikingService.shared.fetchHikings(cityId: cityId, limit: 200)
            let trailImages = trails.flatMap { $0.images ?? [] }
            let waypointImages = trails.flatMap { $0.waypoints }.flatMap { $0.images ?? [] }
            await ImagePrefetcher.prefetch(from: trailImages + waypointImages)
        } catch {
            return
        }
    }

    private func prefetchTransports(cityId: Int32) async {
        do {
            _ = try await PublicTransportService.shared.fetchTransports(cityId: cityId, limit: 400)
        } catch {
            return
        }
    }

    private func prefetchTips(cityId: Int32) async {
        do {
            _ = try await TipService.shared.fetchTips(cityId: cityId, limit: 200)
        } catch {
            return
        }
    }

    private func prefetchAds(cityId: Int32) async {
        do {
            let ads = try await AdService.shared.fetchAds(cityId: cityId, limit: 100)
            await ImagePrefetcher.prefetch(urls: ads.compactMap { $0.displayImage })
        } catch {
            return
        }
    }
}

enum ImagePrefetcher {
    static func prefetch(from images: [ImageContainer]) async {
        let urls = images.compactMap { $0.displayURL }
        await prefetch(urls: urls)
    }

    static func prefetch(urls: [String]) async {
        let uniqueUrls = Array(Set(urls))
        await withTaskGroup(of: Void.self) { group in
            for urlString in uniqueUrls {
                guard let url = URL(string: urlString) else { continue }
                group.addTask {
                    let request = URLRequest(
                        url: url,
                        cachePolicy: .returnCacheDataElseLoad,
                        timeoutInterval: 30
                    )
                    _ = try? await URLSession.shared.data(for: request)
                }
            }
        }
    }
}

extension Notification.Name {
    static let offlinePrefetchCompleted = Notification.Name("offline_prefetch_completed")
    static let offlinePrefetchStatusChanged = Notification.Name("offline_prefetch_status_changed")
}
