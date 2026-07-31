//
//  AllLocationsModel.swift
//  Fielmedina
//
//  Presentation model for the All Locations screen.
//
//  REFERENCE PATTERN — this is the shape every other iOS screen should move to,
//  and the prerequisite for the AI and AR work:
//
//  • State lives here, not in the View. A SwiftUI `View` is a struct that SwiftUI
//    destroys and recreates constantly, so `@State` is the wrong home for anything
//    expensive or long-lived (an AI conversation, an ARSession, an in-flight load).
//    Held by the View as `@State private var model = …`, this object survives body
//    re-evaluation — the same guarantee Android gets from `ViewModel`.
//  • Logic is testable. Nothing here needs SwiftUI, so the filtering, sorting and
//    paging rules can be exercised in a unit test. Logic inside a `View` cannot be.
//  • Dependencies are injected (with production defaults), so a test can pass a
//    different service without touching the call sites.
//

import Foundation
import CoreLocation
import Observation

@MainActor
@Observable
final class AllLocationsModel {

    // MARK: - Published state (was @State in the View)

    private(set) var locations: [Location] = []
    /// Memoized filter + distance sort. Recomputed only when an input changes —
    /// never per body pass, and never per row.
    private(set) var displayedLocations: [Location] = []
    private(set) var categories: [LocationCategory] = []
    private(set) var isLoading = true
    private(set) var isRefreshing = false
    private(set) var isLoadingNextPage = false
    private(set) var errorMessage: String?
    private(set) var hasMoreData = true
    private(set) var isConnected = NetworkMonitor.shared.isConnected

    // MARK: - Filter inputs

    var selectedCityId: String? {
        didSet {
            guard oldValue != selectedCityId else { return }
            applyFilterChange()
        }
    }

    /// Category id, not display name — the server filters by id, so the selection
    /// has to carry one.
    var selectedCategoryId: String? {
        didSet {
            guard oldValue != selectedCategoryId else { return }
            applyFilterChange()
        }
    }

    // MARK: - Paging configuration

    /// The whole catalogue is held locally. This is exactly the query variant the
    /// offline prefetcher warms, so it resolves from the Apollo cache instantly —
    /// online and offline alike — and every filter below runs against local data.
    private let catalogueLimit: Int32 = 500
    /// Rows rendered so far. Grows as the user scrolls: this is DISPLAY paging over
    /// data we already hold, so it never touches the network.
    private var visibleCount = 50
    private let pageSize = 50
    /// Start extending the window this many rows before the end (smoother scrolling).
    private let paginationPrefetchAhead = 3

    // MARK: - Dependencies

    private let locationService: LocationService
    private let categoryService: LocationCategoryService

    /// User position, bucketed to ~100 m so the list re-orders when the user actually
    /// moves rather than on every GPS jitter tick.
    private var userCoordinate: CLLocationCoordinate2D?
    private var userLocationBucket: String?

    /// Internal plumbing, never rendered — `@ObservationIgnored` keeps it a plain
    /// stored property (no observation overhead), and `nonisolated(unsafe)` lets the
    /// non-isolated `deinit` remove the observer. Written once in `init`, read once
    /// in `deinit`, never concurrently.
    @ObservationIgnored nonisolated(unsafe) private var networkObserver: NSObjectProtocol?

    init(
        locationService: LocationService = .shared,
        categoryService: LocationCategoryService = .shared
    ) {
        self.locationService = locationService
        self.categoryService = categoryService

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

    var isFilteringCategory: Bool { selectedCategoryId != nil }

    /// Cities offered by the Regions filter.
    ///
    /// Deliberately NOT derived from the paginated `locations` array: that only holds
    /// the first page, so any city whose locations fall beyond it would silently
    /// vanish from the filter. Built instead from a full snapshot (see
    /// `loadFilterCities`).
    private(set) var availableCities: [LocationCity] = []

    var cityOptions: [FilterMenuOption] {
        [FilterMenuOption(id: nil, label: String(localized: "All Regions"))]
            + availableCities.map { FilterMenuOption(id: $0.id, label: $0.displayName) }
    }

    var categoryOptions: [FilterMenuOption] {
        [FilterMenuOption(id: nil, label: String(localized: "All Locations"))]
            + categories.map { FilterMenuOption(id: $0.id, label: $0.displayName) }
    }

    var emptyStateTitle: String {
        if isFilteringCategory || selectedCityId != nil {
            return String(localized: "No Locations Found")
        }
        return String(localized: "No Locations Yet")
    }

    var emptyStateMessage: String {
        if isFilteringCategory || selectedCityId != nil {
            return String(localized: "There are no locations for this filter yet.\nCheck back soon!")
        }
        return String(localized: "There are no locations in this city yet.\nCheck back soon!")
    }

    /// True when this row sits inside the prefetch window at the end of the list.
    /// Keeps the paging rule here instead of duplicating index math in the View.
    func isNearEnd(_ location: Location) -> Bool {
        guard let index = displayedLocations.firstIndex(where: { $0.id == location.id }) else {
            return false
        }
        return index >= displayedLocations.count - paginationPrefetchAhead
    }

    // MARK: - Inputs from the View

    /// Feeds the user's position in. The View owns CoreLocation permission and
    /// lifecycle; the model only needs the coordinate, which keeps it testable.
    func updateUserLocation(_ coordinate: CLLocationCoordinate2D?) {
        userCoordinate = coordinate
        let bucket = coordinate.map { "\(Int($0.latitude * 1000)),\(Int($0.longitude * 1000))" }
        guard bucket != userLocationBucket else { return }
        userLocationBucket = bucket
        recomputeDisplayedLocations()
    }

    private func handleConnectivityChange(_ connected: Bool) {
        let wasOffline = !isConnected
        isConnected = connected
        // Coming back online: pull fresh data.
        if connected && wasOffline {
            Task { await refreshFromNetwork() }
        }
    }

    // MARK: - Loading

    func loadData(forceRefresh: Bool = false) async {
        if locations.isEmpty {
            isLoading = true
        }
        errorMessage = nil

        let previousLocations = locations
        let previousCategories = categories

        await withTaskGroup(of: Void.self) { group in
            group.addTask { [weak self] in await self?.loadLocations(forceRefresh: forceRefresh) }
            group.addTask { [weak self] in await self?.loadLocationCategories() }
            group.addTask { [weak self] in await self?.loadFilterCities() }
        }

        // Keep whatever we already had if a refresh came back empty (offline, error).
        if locations.isEmpty && !previousLocations.isEmpty {
            locations = previousLocations
        }
        if categories.isEmpty && !previousCategories.isEmpty {
            categories = previousCategories
        }

        // Final offline fallback: derive categories from the loaded locations so
        // filtering still works without a category fetch.
        if categories.isEmpty, !locations.isEmpty {
            var seen = Set<String>()
            categories = locations
                .compactMap { $0.category }
                .filter { seen.insert($0.id).inserted }
                .sorted { $0.displayName < $1.displayName }
        }

        isLoading = false

        // Single funnel point after locations + categories settle.
        recomputeDisplayedLocations()
    }

    func refreshFromNetwork() async {
        guard !isRefreshing else { return }
        isRefreshing = true
        defer { isRefreshing = false }
        await loadData(forceRefresh: true)
    }

    /// Extends the rendered window. Purely local — the rows are already loaded, so
    /// this works identically offline and never waits on the network.
    func loadNextPage() {
        guard hasMoreData else { return }
        visibleCount += pageSize
        recomputeDisplayedLocations()
    }

    /// Loads the whole catalogue.
    ///
    /// OFFLINE-FIRST: this is the exact query variant the prefetcher warms, so it
    /// comes back from the Apollo cache immediately whether or not there is a network.
    /// Filtering then happens locally, which is why changing a filter is instant and
    /// works with no signal at all.
    private func loadLocations(forceRefresh: Bool = false) async {
        errorMessage = nil

        do {
            let fetched = try await locationService.fetchLocations(
                cityId: nil,
                limit: catalogueLimit,
                offset: 0,
                forceRefresh: forceRefresh
            )
            locations = fetched
        } catch {
            if locations.isEmpty {
                errorMessage = error.localizedDescription
            }
        }

        isLoading = false
    }

    /// Filter changed — re-filter the local catalogue and restart the display window.
    /// No network, no loading state: the data is already on the device.
    private func applyFilterChange() {
        visibleCount = pageSize
        recomputeDisplayedLocations()
    }

    /// Builds the Regions filter from the complete location set rather than the
    /// current page or the current filter. Uses the same query variant the offline
    /// prefetcher warms, so this is a cache hit online and works offline.
    private func loadFilterCities() async {
        guard let all = try? await locationService.fetchLocations(
            cityId: nil,
            limit: catalogueLimit,
            offset: 0
        ) else { return }

        var seen = Set<String>()
        availableCities = all
            .compactMap { $0.city }
            .filter { seen.insert($0.id).inserted }
            .sorted { $0.displayName < $1.displayName }
    }

    private func loadLocationCategories() async {
        // 1) Cache-only first
        if let cached = await categoryService.fetchLocationCategoriesFromCache(), !cached.isEmpty {
            categories = cached.sorted { $0.displayName < $1.displayName }
            return
        }

        // 2) Network (cacheFirst), then derive from the loaded locations
        do {
            let fetched = try await categoryService.fetchLocationCategories()
            categories = fetched.sorted { $0.displayName < $1.displayName }
        } catch {
            var seen = Set<String>()
            categories = locations
                .compactMap { $0.category }
                .filter { seen.insert($0.id).inserted }
                .sorted { $0.displayName < $1.displayName }
        }
    }

    // MARK: - Filtering + sorting

    /// Filters and distance-sorts into `displayedLocations`.
    ///
    /// Distances are computed once per item (decorate–sort–undecorate) rather than
    /// allocating two `CLLocation`s per comparison inside the sort predicate.
    /// Filters and distance-sorts the LOCAL catalogue, then slices the visible window.
    /// Runs entirely on-device, so it behaves the same with or without a network.
    private func recomputeDisplayedLocations() {
        var result = locations

        if let cityId = selectedCityId {
            result = result.filter { $0.city?.id == cityId }
        }
        if let categoryId = selectedCategoryId {
            result = result.filter { $0.category?.id == categoryId }
        }

        if let userCoordinate {
            let userLoc = CLLocation(latitude: userCoordinate.latitude, longitude: userCoordinate.longitude)
            result = result
                .map { location -> (location: Location, distance: CLLocationDistance) in
                    let candidate = CLLocation(latitude: location.latitude, longitude: location.longitude)
                    return (location, candidate.distance(from: userLoc))
                }
                .sorted { $0.distance < $1.distance }
                .map(\.location)
        }

        // More rows exist for this filter than we are currently rendering.
        hasMoreData = result.count > visibleCount
        displayedLocations = Array(result.prefix(visibleCount))
    }
}
