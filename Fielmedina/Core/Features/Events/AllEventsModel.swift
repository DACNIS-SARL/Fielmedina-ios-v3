//
//  AllEventsModel.swift
//  Fielmedina
//
//  Presentation model for the All Events screen.
//  Follows the reference pattern documented in `AllLocationsModel`.
//

import Foundation
import Observation

@MainActor
@Observable
final class AllEventsModel {

    // MARK: - Published state

    private(set) var events: [Event] = []
    /// Memoized filter result. Recomputed only when an input changes.
    private(set) var displayedEvents: [Event] = []
    private(set) var categories: [EventCategory] = []
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
    private let catalogueLimit: Int32 = 200
    /// Rows rendered so far. Grows as the user scrolls: DISPLAY paging over data we
    /// already hold, so it never touches the network.
    private var visibleCount = 50
    private let pageSize = 50
    /// Start extending the window this many rows before the end.
    private let paginationPrefetchAhead = 3

    // MARK: - Dependencies

    private let eventService: EventService
    private let categoryService: EventCategoryService

    /// Internal plumbing, never rendered — `@ObservationIgnored` keeps it a plain
    /// stored property (no observation overhead), and `nonisolated(unsafe)` lets the
    /// non-isolated `deinit` remove the observer. Written once in `init`, read once
    /// in `deinit`, never concurrently.
    @ObservationIgnored nonisolated(unsafe) private var networkObserver: NSObjectProtocol?

    init(
        eventService: EventService = .shared,
        categoryService: EventCategoryService = .shared
    ) {
        self.eventService = eventService
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

    /// Cities offered by the Regions filter.
    ///
    /// Deliberately NOT derived from the paginated `events` array: that only holds the
    /// first page, so any city whose events fall beyond it would silently vanish from
    /// the filter. Built instead from a full snapshot (see `loadFilterCities`).
    private(set) var availableCities: [EventCity] = []

    var cityOptions: [FilterMenuOption] {
        [FilterMenuOption(id: nil, label: String(localized: "All Regions"))]
            + availableCities.map { FilterMenuOption(id: $0.id, label: $0.displayName) }
    }

    var categoryOptions: [FilterMenuOption] {
        [FilterMenuOption(id: nil, label: String(localized: "All Events"))]
            + categories.map { FilterMenuOption(id: $0.id, label: $0.displayName) }
    }

    var isFilteringCategory: Bool { selectedCategoryId != nil }

    /// True when this row sits inside the prefetch window at the end of the list.
    func isNearEnd(_ event: Event) -> Bool {
        guard let index = displayedEvents.firstIndex(where: { $0.id == event.id }) else {
            return false
        }
        return index >= displayedEvents.count - paginationPrefetchAhead
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
        if events.isEmpty {
            isLoading = true
        }
        errorMessage = nil

        let previousEvents = events
        let previousCategories = categories

        await withTaskGroup(of: Void.self) { group in
            group.addTask { [weak self] in await self?.loadEvents(forceRefresh: forceRefresh) }
            group.addTask { [weak self] in await self?.loadCategories() }
            group.addTask { [weak self] in await self?.loadFilterCities() }
        }

        // Keep whatever we already had if a refresh came back empty (offline, error).
        if events.isEmpty && !previousEvents.isEmpty {
            events = previousEvents
        }
        if categories.isEmpty && !previousCategories.isEmpty {
            categories = previousCategories
        }

        // Final offline fallback: derive categories from the loaded events.
        if categories.isEmpty, !events.isEmpty {
            var seen = Set<String>()
            categories = events
                .compactMap { $0.category }
                .filter { seen.insert($0.id).inserted }
                .sorted { $0.displayName < $1.displayName }
        }

        isLoading = false

        // Single funnel point after events + categories settle.
        recomputeDisplayedEvents()
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
        recomputeDisplayedEvents()
    }

    /// Loads the whole catalogue.
    ///
    /// OFFLINE-FIRST: this is the exact query variant the prefetcher warms, so it comes
    /// back from the Apollo cache immediately whether or not there is a network.
    /// Filtering then happens locally, which is why changing a filter is instant and
    /// works with no signal at all.
    private func loadEvents(forceRefresh: Bool = false) async {
        do {
            let fetched = try await eventService.fetchEvents(
                limit: catalogueLimit,
                offset: 0,
                forceRefresh: forceRefresh
            )
            events = fetched
        } catch {
            if events.isEmpty {
                errorMessage = error.localizedDescription
            }
        }
    }

    /// Filter changed — re-filter the local catalogue and restart the display window.
    /// No network, no loading state: the data is already on the device.
    private func applyFilterChange() {
        visibleCount = pageSize
        recomputeDisplayedEvents()
    }

    /// Builds the Regions filter from the complete event set rather than the current
    /// page. Uses the same query variant the offline prefetcher warms, so this is a
    /// cache hit online and works offline.
    private func loadFilterCities() async {
        guard let all = try? await eventService.fetchEvents(
            limit: catalogueLimit,
            offset: 0
        ) else { return }

        var seen = Set<String>()
        availableCities = all
            .compactMap { $0.city }
            .filter { seen.insert($0.id).inserted }
            .sorted { $0.displayName < $1.displayName }
    }

    private func loadCategories() async {
        do {
            let fetched = try await categoryService.fetchEventCategories()
            categories = fetched.sorted { $0.displayName < $1.displayName }
        } catch {
            // Offline or fetch failed — derive categories from already-loaded events.
            var seen = Set<String>()
            categories = events
                .compactMap { $0.category }
                .filter { seen.insert($0.id).inserted }
                .sorted { $0.displayName < $1.displayName }
        }
    }

    // MARK: - Filtering

    /// Filters the LOCAL catalogue, then slices the visible window. Runs entirely
    /// on-device, so it behaves the same with or without a network.
    private func recomputeDisplayedEvents() {
        var result = events

        if let cityId = selectedCityId {
            result = result.filter { $0.city?.id == cityId }
        }
        if let categoryId = selectedCategoryId {
            result = result.filter { $0.category?.id == categoryId }
        }

        hasMoreData = result.count > visibleCount
        displayedEvents = Array(result.prefix(visibleCount))
    }
}
