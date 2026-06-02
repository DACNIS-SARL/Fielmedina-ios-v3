//
//  OfflineContentPrefetcher.swift
//  Fielmedina
//
//  Created by Aslan on 1/26/26.
//

import Foundation
import CoreLocation
import Apollo
import UIKit

@MainActor
final class OfflineContentPrefetcher {
    static let shared = OfflineContentPrefetcher()

    private let completionKey = "offline_prefetch_completed"
    private let statusKey = "offline_prefetch_status"
    private let progressKey = "offline_prefetch_progress"
    private var isRunning = false
    private var isObservingLocation = false
    private var retryTask: Task<Void, Never>?

    enum Status: Equatable {
        case idle
        case downloading(String)
        case waitingForLocation
        case permissionDenied
        case failed(String)
        case completed

        var rawValue: String {
            switch self {
            case .idle: return "idle"
            case .downloading(let msg): return "downloading:\(msg)"
            case .waitingForLocation: return "waitingForLocation"
            case .permissionDenied: return "permissionDenied"
            case .failed(let err): return "failed:\(err)"
            case .completed: return "completed"
            }
        }

        static func from(rawValue: String) -> Status {
            if rawValue.hasPrefix("downloading:") {
                return .downloading(String(rawValue.dropFirst(12)))
            }
            if rawValue.hasPrefix("failed:") {
                return .failed(String(rawValue.dropFirst(7)))
            }
            switch rawValue {
            case "idle": return .idle
            case "waitingForLocation": return .waitingForLocation
            case "permissionDenied": return .permissionDenied
            case "completed": return .completed
            default: return .idle
            }
        }
    }

    var isComplete: Bool {
        UserDefaults.standard.bool(forKey: completionKey)
    }

    var status: Status {
        if isComplete {
            return .completed
        }
        if let rawValue = UserDefaults.standard.string(forKey: statusKey) {
            return Status.from(rawValue: rawValue)
        }
        return .idle
    }

    var progress: Double {
        if isComplete {
            return 1
        }
        return UserDefaults.standard.double(forKey: progressKey)
    }

    func markNeedsRefresh() {
        UserDefaults.standard.set(false, forKey: completionKey)
        updateStatus(.idle)
        updateProgress(0)
    }

    func prefetchForCity(_ cityId: Int32) {
        guard !isRunning else { return }
        isRunning = true
        updateProgress(0)

        Task {
            let didComplete = await runPrefetch()
            isRunning = false
            if !didComplete {
                handleFailedPrefetch()
            }
        }
    }

    func prefetchIfNeeded() {
        // Warm categories cache regardless of completion state
        Task { await self.prefetchEventCategories() }
        Task { await self.prefetchLocationCategories() }

        guard !isRunning, !isComplete else { return }
        isRunning = true
        updateProgress(0)

        Task {
            let didComplete = await runPrefetch()
            isRunning = false
            if !didComplete {
                handleFailedPrefetch()
            }
        }
    }

    private func runPrefetch() async -> Bool {
        updateStatus(.downloading(String(localized: "Initializing...")))
        _ = await resolveCityIdIfPossible()

        // Phase 1: Metadata Fetching
        updateStatus(.downloading(String(localized: "Fetching data...")))
        
        var imageUrls = Set<String>()
        
        // We use a simplified sequential fetch for metadata to collect all URLs
        let metadataTasks: [() async -> Void] = [
            { await self.prefetchEventCategories() },
            { await self.prefetchLocationCategories() },
            { await self.prefetchTransports() }
        ]
        
        for task in metadataTasks {
            await task()
        }
        
        // Fetch entities and extract images
        imageUrls.formUnion(await fetchLocationImageUrls())
        imageUrls.formUnion(await fetchEventImageUrls())
        imageUrls.formUnion(await fetchHikingImageUrls())
        imageUrls.formUnion(await fetchTipImageUrls())
        imageUrls.formUnion(await fetchAdImageUrls())
        imageUrls.formUnion(await fetchMerchantImageUrls())
        
        let imageUrlList = Array(imageUrls).filter { !$0.isEmpty }
        
        if imageUrlList.isEmpty {
            finalizePrefetch()
            return true
        }
        
        // Phase 2: Images + voiceovers (AAC) — voice files use disk cache for offline playback.
        let prefetcher = ImagePrefetcher()
        
        for await progressUpdate in await prefetcher.prefetch(urls: imageUrlList) {
            updateProgress(progressUpdate.fraction)
            let statusMsg = String(localized: "Downloading images (\(progressUpdate.completed)/\(progressUpdate.total))")
            updateStatus(.downloading(statusMsg))
        }
        
        finalizePrefetch()
        return true
    }
    
    private func finalizePrefetch() {
        UserDefaults.standard.set(true, forKey: completionKey)
        updateStatus(.completed)
        updateProgress(1)
        NotificationCenter.default.post(name: .offlinePrefetchCompleted, object: nil)
    }

    private func resolveCityIdIfPossible() async -> Bool {
        if CitySelectionStore.shared.cityId != nil {
            return true
        }

        LocationManager.shared.requestPermission()
        LocationManager.shared.startUpdatingLocation()

        if LocationManager.shared.authorizationStatus == .denied
            || LocationManager.shared.authorizationStatus == .restricted {
            updateStatus(.permissionDenied)
            return false
        }

        var coordinate: CLLocationCoordinate2D?
        for _ in 0..<10 {
            if let currentCoordinate = LocationManager.shared.userLocation {
                coordinate = currentCoordinate
                break
            }
            try? await Task.sleep(for: .seconds(1))
        }

        guard let coordinate else { 
            updateStatus(.waitingForLocation)
            return false 
        }

        do {
            let query = FielmedinaAPI.GetNearestCityQuery(
                lat: coordinate.latitude,
                lon: coordinate.longitude
            )
            let data = try await Network.shared.apollo.fetchNetworkAware(query: query)
            if let cityIdString = data.nearestCity?.id,
               let cityId = Int32(cityIdString) {
                CitySelectionStore.shared.cityId = cityId
                return true
            }
        } catch {
            return false
        }

        return false
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

    private func updateProgress(_ progress: Double) {
        UserDefaults.standard.set(progress, forKey: progressKey)
        NotificationCenter.default.post(name: .offlinePrefetchProgressChanged, object: progress)
    }

    // MARK: - Metadata Fetchers
    
    private func fetchLocationImageUrls() async -> Set<String> {
        let cityId = CitySelectionStore.shared.cityId
        do {
            // 1) Prefetch exact query variants used by AllLocationsList (limit:50, offset:0)
            _ = try? await LocationService.shared.fetchLocations(cityId: nil, limit: 50)
            if let id = cityId {
                _ = try? await LocationService.shared.fetchLocations(cityId: id, limit: 50)
            }
            
            // 2) Prefetch variants used by CarouselListLocations (limit:10)
            _ = try? await LocationService.shared.fetchLocations(cityId: nil, limit: 10)
            if let id = cityId {
                _ = try? await LocationService.shared.fetchLocations(cityId: id, limit: 500)
            }

            let locations = try await LocationService.shared.fetchLocations(cityId: nil, limit: 500)
            var urls = extractUrls(from: locations.flatMap { $0.images ?? [] })
            urls.formUnion(Self.voiceoverRemoteURLs(from: locations))
            return urls
        } catch { return [] }
    }

    private static func voiceoverRemoteURLs(from locations: [Location]) -> Set<String> {
        var out = Set<String>()
        for loc in locations {
            if let e = loc.voiceoverEn?.trimmingCharacters(in: .whitespacesAndNewlines), !e.isEmpty {
                out.insert(e)
            }
            if let f = loc.voiceoverFr?.trimmingCharacters(in: .whitespacesAndNewlines), !f.isEmpty {
                out.insert(f)
            }
        }
        return out
    }

    private func fetchEventImageUrls() async -> Set<String> {
        let cityId = CitySelectionStore.shared.cityId
        do {
            // 1) Prefetch exact query variants used by AllEventList (limit:50, offset:0)
            _ = try? await EventService.shared.fetchEvents(cityId: nil, limit: 50)
            if let id = cityId {
                _ = try? await EventService.shared.fetchEvents(cityId: id, limit: 50)
            }

            // 2) Prefetch variants used by CarouselListEvent (limit:5, boost:true)
            _ = try? await EventService.shared.fetchEvents(cityId: nil, limit: 5, boost: true)
            if let id = cityId {
                _ = try? await EventService.shared.fetchEvents(cityId: id, limit: 5, boost: true)
            }
            
            // 3) Pagination variants (batches of 50)
            _ = try? await EventService.shared.fetchEvents(limit: 50, boost: true)
            
            let events = try await EventService.shared.fetchEvents(limit: 200)
            let boostedEvents = (try? await EventService.shared.fetchEvents(limit: 200, boost: true)) ?? []
            return extractUrls(from: (events + boostedEvents).flatMap { $0.images ?? [] })
        } catch { return [] }
    }

    private func fetchHikingImageUrls() async -> Set<String> {
        do {
            let trails = try await HikingService.shared.fetchHikings(cityId: nil, limit: 200)
            let trailImages = extractUrls(from: trails.flatMap { $0.images ?? [] })
            let waypointImages = extractUrls(from: trails.flatMap { $0.waypoints }.flatMap { $0.images ?? [] })
            return trailImages.union(waypointImages)
        } catch { return [] }
    }
    
    private func fetchTipImageUrls() async -> Set<String> {
        do {
            _ = try await TipService.shared.fetchTips(cityId: nil, limit: 500)
            return []
        } catch { return [] }
    }

    private func fetchAdImageUrls() async -> Set<String> {
        do {
            let ads = try await AdService.shared.fetchAds(cityId: nil, limit: 100)
            return Set(ads.compactMap { ad in
                if UIDevice.current.userInterfaceIdiom == .pad {
                    return ad.imageTablet?.url ?? ad.imageMobile?.url
                } else {
                    return ad.imageMobile?.url ?? ad.imageTablet?.url
                }
            })
        } catch { return [] }
    }

    private func fetchMerchantImageUrls() async -> Set<String> {
        let cityId = CitySelectionStore.shared.cityId
        do {
            _ = try? await MerchantService.shared.fetchMerchants(cityId: nil, limit: 50)
            if let id = cityId {
                _ = try? await MerchantService.shared.fetchMerchants(cityId: id, limit: 50)
            }
            let merchants = try await MerchantService.shared.fetchMerchants(limit: 200)
            return extractUrls(from: merchants.flatMap { $0.images ?? [] })
        } catch { return [] }
    }

    private func prefetchEventCategories() async {
        _ = try? await EventCategoryService.shared.fetchEventCategories()
    }

    private func prefetchLocationCategories() async {
        _ = try? await LocationCategoryService.shared.fetchLocationCategories()
    }

    private func prefetchTransports() async {
        _ = try? await PublicTransportService.shared.fetchTransports(limit: 400)
    }
    
    private func extractUrls(from containers: [ImageContainer]) -> Set<String> {
        let isPad = UIDevice.current.userInterfaceIdiom == .pad
        return Set(containers.compactMap { container in
            if isPad {
                return container.image?.url ?? container.imageMobile?.url
            } else {
                return container.imageMobile?.url ?? container.image?.url
            }
        })
    }
}

// MARK: - ImagePrefetcher

actor ImagePrefetcher {
    struct Progress {
        let completed: Int
        let total: Int
        var fraction: Double { Double(completed) / Double(max(total, 1)) }
    }
    
    private let maxConcurrentDownloads = 6
    
    func prefetch(urls: [String]) -> AsyncStream<Progress> {
        let uniqueUrls = Array(Set(urls))
        let total = uniqueUrls.count
        
        return AsyncStream { continuation in
            Task {
                var completed = 0
                
                await withTaskGroup(of: Void.self) { group in
                    var currentIndex = 0
                    
                    // Fill initial queue
                    while currentIndex < min(total, maxConcurrentDownloads) {
                        let url = uniqueUrls[currentIndex]
                        group.addTask { await self.download(url: url) }
                        currentIndex += 1
                    }
                    
                    // As one finish, add another
                    for await _ in group {
                        completed += 1
                        continuation.yield(Progress(completed: completed, total: total))
                        
                        if currentIndex < total {
                            let url = uniqueUrls[currentIndex]
                            group.addTask { await self.download(url: url) }
                            currentIndex += 1
                        }
                    }
                }
                continuation.finish()
            }
        }
    }
    
    private func download(url urlString: String, attempt: Int = 1) async {
        guard let remote = URL(string: urlString) else { return }

        let path = remote.path.lowercased()
        let isVoiceoverAsset =
            path.contains("voiceover")
            || path.hasSuffix(".aac")
            || path.hasSuffix(".m4a")

        if isVoiceoverAsset {
            do {
                try await VoiceoverDiskCache.downloadIfNeeded(remote: remote)
            } catch {
                if attempt < 3 {
                    try? await Task.sleep(for: .seconds(Double(attempt) * 2))
                    await download(url: urlString, attempt: attempt + 1)
                }
            }
            return
        }

        let request = URLRequest(
            url: remote,
            cachePolicy: .returnCacheDataElseLoad,
            timeoutInterval: 20
        )

        do {
            _ = try await URLSession.shared.data(for: request)
        } catch {
            if attempt < 3 {
                try? await Task.sleep(for: .seconds(Double(attempt) * 2))
                await download(url: urlString, attempt: attempt + 1)
            }
        }
    }
}

extension Notification.Name {
    static let offlinePrefetchCompleted = Notification.Name("offline_prefetch_completed")
    static let offlinePrefetchStatusChanged = Notification.Name("offline_prefetch_status_changed")
    static let offlinePrefetchProgressChanged = Notification.Name("offline_prefetch_progress_changed")
}
