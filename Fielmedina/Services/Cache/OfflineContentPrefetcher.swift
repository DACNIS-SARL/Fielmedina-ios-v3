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
    private let lastPrefetchDateKey = "offline_prefetch_last_date"
    // New content is published daily, so refresh the offline snapshot once a day.
    // Already-downloaded images and voiceovers are skipped, so only deltas are fetched.
    private let staleRefreshInterval: TimeInterval = 24 * 60 * 60
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

        // The completion flag lives in UserDefaults and survives iOS purging the
        // Caches directory, so verify the data actually still exists on disk.
        // Consume the flag unconditionally: on a fresh install it is also set, and
        // must not linger past the first prefetch or it would trigger a re-download.
        let graphQLCacheWasRecreated = CacheConfigurator.consumeGraphQLCacheFreshFlag()
        if isComplete && (graphQLCacheWasRecreated || offlineDataIsMissing()) {
            markNeedsRefresh()
        }

        guard !isRunning else { return }

        if isComplete {
            refreshStaleDataIfNeeded()
            return
        }

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

    /// Detects the case where iOS evicted the offline data while the app was unused:
    /// the "prefetch completed" flag survives in UserDefaults, but the GraphQL store is gone.
    private func offlineDataIsMissing() -> Bool {
        !FileManager.default.fileExists(atPath: CacheConfigurator.graphQLCacheFileURL.path)
    }

    /// Silently re-runs the prefetch when the last one is older than `staleRefreshInterval`,
    /// so content added to the backend since then becomes available offline too. The
    /// completion flag stays true, so existing offline data keeps serving meanwhile.
    private func refreshStaleDataIfNeeded() {
        guard NetworkMonitor.shared.isConnected else { return }

        guard let lastPrefetch = UserDefaults.standard.object(forKey: lastPrefetchDateKey) as? Date else {
            // Older app versions never stored the date; stamp now to start the clock.
            UserDefaults.standard.set(Date(), forKey: lastPrefetchDateKey)
            return
        }
        guard Date().timeIntervalSince(lastPrefetch) > staleRefreshInterval else { return }

        isRunning = true
        Task {
            _ = await runPrefetch()
            isRunning = false
        }
    }

    private func runPrefetch() async -> Bool {
        guard NetworkMonitor.shared.isConnected else {
            updateStatus(.failed(String(localized: "No internet connection")))
            return false
        }

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
            // Real content always yields image URLs, so an empty list means the
            // metadata fetches failed (server unreachable, connection dropped mid-run).
            // Don't mark complete with nothing cached — fail and let the retry handle it.
            updateStatus(.failed(String(localized: "Download failed")))
            return false
        }
        
        // Phase 2: Images + voiceovers (AAC) — voice files use disk cache for offline playback.
        let prefetcher = ImagePrefetcher()
        
        for await progressUpdate in await prefetcher.prefetch(urls: imageUrlList) {
            updateProgress(progressUpdate.fraction)
            let statusMsg = String(localized: "Downloading data (\(progressUpdate.completed)/\(progressUpdate.total))")
            updateStatus(.downloading(statusMsg))
        }
        
        finalizePrefetch()
        return true
    }
    
    private func finalizePrefetch() {
        UserDefaults.standard.set(true, forKey: completionKey)
        UserDefaults.standard.set(Date(), forKey: lastPrefetchDateKey)
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
            // 1) Prefetch exact query variants used by AllMerchants list (limit:50)
            _ = try? await MerchantService.shared.fetchMerchants(cityId: nil, limit: 50)
            if let id = cityId {
                _ = try? await MerchantService.shared.fetchMerchants(cityId: id, limit: 50)
            }
            
            // 2) Prefetch exact query variants used by CarouselListMerchants (limit:10)
            _ = try? await MerchantService.shared.fetchMerchants(cityId: nil, limit: 10)
            if let id = cityId {
                _ = try? await MerchantService.shared.fetchMerchants(cityId: id, limit: 10)
            }
            
            // 3) Fetch all merchants for image extraction
            let merchants = try await MerchantService.shared.fetchMerchants(limit: 200)
            var urls = extractUrls(from: merchants.flatMap { $0.images ?? [] })
            
            // 3) Prefetch individual merchant details (populates Apollo cache with products/ratings)
            //    This ensures MerchantDetailView works fully offline.
            //    Bounded concurrency: fetching every merchant's detail at once floods the
            //    network (competing with image + Mapbox tile downloads) and spikes RAM with
            //    hundreds of in-flight responses. A sliding window of 4 keeps both in check.
            var productImageUrls = Set<String>()
            let isPad = UIDevice.current.userInterfaceIdiom == .pad
            let maxConcurrentDetails = 4
            await withTaskGroup(of: Set<String>.self) { group in
                var index = 0
                while index < min(merchants.count, maxConcurrentDetails) {
                    let id = merchants[index].id
                    group.addTask { await Self.merchantDetailImageUrls(id: id, isPad: isPad) }
                    index += 1
                }
                for await result in group {
                    productImageUrls.formUnion(result)
                    if index < merchants.count {
                        let id = merchants[index].id
                        group.addTask { await Self.merchantDetailImageUrls(id: id, isPad: isPad) }
                        index += 1
                    }
                }
            }

            urls.formUnion(productImageUrls)
            return urls
        } catch { return [] }
    }

    /// Fetches one merchant's detail (warming the Apollo cache for offline use) and
    /// returns its product + carousel image URLs. `nonisolated` so the concurrent
    /// prefetch runs off the main actor.
    nonisolated private static func merchantDetailImageUrls(id: String, isPad: Bool) async -> Set<String> {
        do {
            let detail = try await MerchantService.shared.fetchMerchant(id: id)
            var pUrls = Set<String>()
            if let products = detail.products {
                for product in products {
                    if let imageUrl = product.image, !imageUrl.isEmpty {
                        pUrls.insert(imageUrl)
                    }
                }
            }
            pUrls.formUnion(
                Set((detail.images ?? []).compactMap { container in
                    if isPad {
                        return container.image?.url ?? container.imageMobile?.url
                    } else {
                        return container.imageMobile?.url ?? container.image?.url
                    }
                })
            )
            return pUrls
        } catch {
            return []
        }
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
    // While the user is downloading an offline map region, drop to a trickle so the
    // map download (which the user is watching) keeps the bandwidth.
    private let throttledConcurrentDownloads = 1

    /// Concurrency to use right now — throttled while a user map download is active.
    private func currentConcurrencyLimit() async -> Int {
        let mapDownloadActive = await MainActor.run { OfflineMapsManager.isUserRegionDownloadActive }
        return mapDownloadActive ? throttledConcurrentDownloads : maxConcurrentDownloads
    }

    func prefetch(urls: [String]) -> AsyncStream<Progress> {
        let uniqueUrls = Array(Set(urls))
        let total = uniqueUrls.count

        return AsyncStream { continuation in
            Task {
                var completed = 0
                var nextIndex = 0
                var inFlight = 0

                await withTaskGroup(of: Void.self) { group in
                    // Launch as many downloads as the current limit allows. When the
                    // limit drops mid-run (a map download started), the in-flight count
                    // simply drains down to the new limit before more are added.
                    func fillWindow() async {
                        let limit = await self.currentConcurrencyLimit()
                        while inFlight < limit && nextIndex < total {
                            let url = uniqueUrls[nextIndex]
                            nextIndex += 1
                            inFlight += 1
                            group.addTask { await self.download(url: url) }
                        }
                    }

                    await fillWindow()

                    for await _ in group {
                        completed += 1
                        inFlight -= 1
                        continuation.yield(Progress(completed: completed, total: total))
                        await fillWindow()
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

        // Already persisted durably — nothing to do.
        if MediaDiskCache.hasCachedData(forRemote: remote) { return }

        let request = URLRequest(
            url: remote,
            cachePolicy: .returnCacheDataElseLoad,
            timeoutInterval: 20
        )

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            MediaDiskCache.store(data, forRemote: remote)
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
