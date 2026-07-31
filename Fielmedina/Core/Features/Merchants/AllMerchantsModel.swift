//
//  AllMerchantsModel.swift
//  Fielmedina
//
//  Presentation model for the All Picks (merchants) screen.
//  Follows the reference pattern documented in `AllLocationsModel`.
//

import Foundation
import CoreLocation
import Observation

@MainActor
@Observable
final class AllMerchantsModel {

    // MARK: - Published state

    private(set) var merchants: [Merchant] = []
    /// Memoized filter + distance sort. Recomputed only when an input changes.
    private(set) var displayedMerchants: [Merchant] = []
    private(set) var categories: [String] = [String(localized: "All Picks")]
    private(set) var isLoading = true
    private(set) var isRefreshing = false
    private(set) var isLoadingNextPage = false
    private(set) var errorMessage: String?
    private(set) var hasMoreData = true
    private(set) var isConnected = NetworkMonitor.shared.isConnected

    // MARK: - Filter input

    var selectedCategory: String = String(localized: "All Picks") {
        didSet {
            guard oldValue != selectedCategory else { return }
            recomputeDisplayedMerchants()
        }
    }

    // MARK: - Paging configuration

    /// Rows fetched per page while online. No overall ceiling — paging continues
    /// until the server returns a short page.
    private let pageSize: Int32 = 50
    /// Start loading the next page this many rows before the end.
    private let paginationPrefetchAhead = 3
    /// Offline, only the prefetcher's warmed query variant exists in the cache, so
    /// load that whole snapshot at once instead of paginating.
    private let offlineSnapshotLimit: Int32 = 200

    // MARK: - Dependencies

    private let merchantService: MerchantService

    /// User position, bucketed to ~100 m so the list re-orders when the user actually
    /// moves rather than on every GPS jitter tick.
    private var userCoordinate: CLLocationCoordinate2D?
    private var userLocationBucket: String?

    /// Internal plumbing, never rendered — `@ObservationIgnored` keeps it a plain
    /// stored property (no observation overhead), and `nonisolated(unsafe)` lets the
    /// non-isolated `deinit` remove the observer. Written once in `init`, read once
    /// in `deinit`, never concurrently.
    @ObservationIgnored nonisolated(unsafe) private var networkObserver: NSObjectProtocol?

    init(merchantService: MerchantService = .shared) {
        self.merchantService = merchantService

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
        if let networkObserver {
            NotificationCenter.default.removeObserver(networkObserver)
        }
    }

    // MARK: - Derived values for the View

    var isFilteringCategory: Bool {
        selectedCategory != String(localized: "All Picks")
    }

    var emptyStateTitle: String {
        isFilteringCategory
            ? String(localized: "No Picks Found")
            : String(localized: "No Picks Yet")
    }

    var emptyStateMessage: String {
        isFilteringCategory
            ? String(localized: "There are no picks in this category yet.\nCheck back soon!")
            : String(localized: "There are no picks available yet.\nCheck back soon!")
    }

    /// True when this row sits inside the prefetch window at the end of the list.
    func isNearEnd(_ merchant: Merchant) -> Bool {
        guard let index = displayedMerchants.firstIndex(where: { $0.id == merchant.id }) else {
            return false
        }
        return index >= displayedMerchants.count - paginationPrefetchAhead
    }

    // MARK: - Inputs from the View

    /// Feeds the user's position in. The View owns CoreLocation permission and
    /// lifecycle; the model only needs the coordinate, which keeps it testable.
    func updateUserLocation(_ coordinate: CLLocationCoordinate2D?) {
        userCoordinate = coordinate
        let bucket = coordinate.map { "\(Int($0.latitude * 1000)),\(Int($0.longitude * 1000))" }
        guard bucket != userLocationBucket else { return }
        userLocationBucket = bucket
        recomputeDisplayedMerchants()
    }

    private func handleConnectivityChange(_ connected: Bool) {
        let wasOffline = !isConnected
        isConnected = connected
        if connected && wasOffline {
            Task { await refreshFromNetwork() }
        }
    }

    // MARK: - Loading

    func loadData(forceRefresh: Bool = false) async {
        if merchants.isEmpty {
            isLoading = true
        }
        errorMessage = nil

        let previousMerchants = merchants
        let previousCategories = categories

        await loadMerchants(forceRefresh: forceRefresh)

        // Keep whatever we already had if a refresh came back empty (offline, error).
        if merchants.isEmpty && !previousMerchants.isEmpty {
            merchants = previousMerchants
        }

        let derived = Array(Set(merchants.compactMap { $0.category?.displayName })).sorted()
        categories = [String(localized: "All Picks")] + derived

        if categories.count == 1 && previousCategories.count > 1 {
            categories = previousCategories
        }

        isLoading = false

        // Single funnel point after merchants + categories settle.
        recomputeDisplayedMerchants()
    }

    func refreshFromNetwork() async {
        guard !isRefreshing else { return }
        isRefreshing = true
        defer { isRefreshing = false }
        await loadData(forceRefresh: true)
    }

    /// Appends the next page when the user approaches the bottom of the list.
    func loadNextPage() async {
        guard isConnected, hasMoreData, !isLoadingNextPage, !isLoading, !isRefreshing else { return }
        isLoadingNextPage = true
        defer { isLoadingNextPage = false }

        do {
            let fetched = try await merchantService.fetchMerchants(
                cityId: nil,
                categoryId: nil,
                limit: pageSize,
                offset: Int32(merchants.count)
            )
            // Guard against duplicates in case rows shifted between page requests.
            var seen = Set(merchants.map(\.id))
            let newItems = fetched.filter { seen.insert($0.id).inserted }
            merchants.append(contentsOf: newItems)

            hasMoreData = fetched.count >= Int(pageSize)
            recomputeDisplayedMerchants()
        } catch {
            // Keep what we have; scrolling to the bottom again retries.
        }
    }

    /// Loads the first page (or, offline, the whole prefetched snapshot).
    private func loadMerchants(forceRefresh: Bool = false) async {
        errorMessage = nil

        do {
            let limit = isConnected ? pageSize : offlineSnapshotLimit

            let fetchedMerchants = try await merchantService.fetchMerchants(
                cityId: nil,
                categoryId: nil,
                limit: limit,
                offset: 0,
                forceRefresh: forceRefresh
            )

            merchants = fetchedMerchants
            hasMoreData = isConnected && fetchedMerchants.count >= Int(limit)
        } catch {
            if merchants.isEmpty {
                errorMessage = error.localizedDescription
            }
        }
    }

    // MARK: - Filtering + sorting

    /// Distances are computed once per item (decorate–sort–undecorate) rather than
    /// allocating two `CLLocation`s per comparison inside the sort predicate.
    private func recomputeDisplayedMerchants() {
        var result = merchants

        let allPicksLabel = String(localized: "All Picks")
        if selectedCategory != allPicksLabel {
            result = result.filter { $0.category?.displayName == selectedCategory }
        }

        if let userCoordinate {
            let userLoc = CLLocation(latitude: userCoordinate.latitude, longitude: userCoordinate.longitude)
            result = result
                .map { merchant -> (merchant: Merchant, distance: CLLocationDistance) in
                    let candidate = CLLocation(
                        latitude: merchant.latitude ?? 0.0,
                        longitude: merchant.longitude ?? 0.0
                    )
                    return (merchant, candidate.distance(from: userLoc))
                }
                .sorted { $0.distance < $1.distance }
                .map(\.merchant)
        }

        displayedMerchants = result
    }
}
