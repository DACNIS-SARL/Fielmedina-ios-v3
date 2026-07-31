//
//  MapContentModel.swift
//  Fielmedina
//
//  Presentation model for the Map screen's *data* — locations, categories and the
//  category filter. Follows the reference pattern documented in `AllLocationsModel`.
//
//  Note on scope: camera/viewport state deliberately stays in the View. It is
//  SwiftUI/Mapbox rendering state, not app data, and Mapbox's `Viewport` wants to
//  live next to the map. The same split will apply to AR: the session's *data*
//  (anchors, recognized places, results) belongs in a model; the rendering state
//  belongs with the view that owns the renderer.
//

import Foundation
import Observation

@MainActor
@Observable
final class MapContentModel {

    // MARK: - Published state

    private(set) var locations: [Location] = []
    private(set) var locationCategories: [LocationCategory] = []
    /// Memoized filter result, recomputed only when the selection or data changes.
    private(set) var displayedLocations: [Location] = []
    private(set) var isConnected = NetworkMonitor.shared.isConnected

    /// Categories currently shown. Empty means "nothing selected yet"; the initial
    /// load selects them all.
    var selectedCategoryIds: Set<String> = [] {
        didSet {
            guard oldValue != selectedCategoryIds else { return }
            recomputeDisplayedLocations()
        }
    }

    // MARK: - Configuration

    /// Matches the prefetcher's cached query variant so the map works offline.
    private let locationsLimit: Int32 = 500

    // MARK: - Dependencies

    private let locationService: LocationService
    private let categoryService: LocationCategoryService

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

    private func handleConnectivityChange(_ connected: Bool) {
        let wasOffline = !isConnected
        isConnected = connected
        if connected && wasOffline {
            Task { await refreshFromNetwork() }
        }
    }

    // MARK: - Loading

    func loadData() async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask { [weak self] in await self?.loadLocations() }
            group.addTask { [weak self] in await self?.loadLocationCategories() }
        }
        selectAllCategoriesIfNeeded()
        recomputeDisplayedLocations()
    }

    func refreshFromNetwork() async {
        await loadData()
    }

    private func loadLocations() async {
        do {
            locations = try await locationService.fetchLocations(
                cityId: nil,
                limit: locationsLimit
            )
        } catch {
            locations = []
        }
    }

    private func loadLocationCategories() async {
        // 1) Cache-only first, to support offline
        if let cached = await categoryService.fetchLocationCategoriesFromCache(), !cached.isEmpty {
            locationCategories = cached.sorted { $0.displayName < $1.displayName }
            return
        }

        // 2) Network (cacheFirst), then derive from the loaded locations
        do {
            let fetched = try await categoryService.fetchLocationCategories()
            locationCategories = fetched.sorted { $0.displayName < $1.displayName }
        } catch {
            var seen = Set<String>()
            locationCategories = locations
                .compactMap { $0.category }
                .filter { seen.insert($0.id).inserted }
                .sorted { $0.displayName < $1.displayName }
        }
    }

    /// On first load, show every category rather than an empty map.
    private func selectAllCategoriesIfNeeded() {
        guard selectedCategoryIds.isEmpty, !locationCategories.isEmpty else { return }
        selectedCategoryIds = Set(locationCategories.map { $0.id })
    }

    // MARK: - Filtering

    private func recomputeDisplayedLocations() {
        guard !selectedCategoryIds.isEmpty else {
            displayedLocations = locations
            return
        }
        displayedLocations = locations.filter { location in
            guard let categoryId = location.category?.id else { return false }
            return selectedCategoryIds.contains(categoryId)
        }
    }
}
