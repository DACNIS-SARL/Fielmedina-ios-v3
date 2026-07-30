//
//  AllLocationList.swift
//  Fielmedina
//
//  Created by Aslan on 1/16/26.
//

import SwiftUI
import CoreLocation

struct AllLocationListView: View {
    @State private var locations: [Location] = []
    @State private var locationManager = LocationManager()
    @State private var selectedCategory: String = String(localized: "All Locations")
    @State private var categories: [String] = [String(localized: "All Locations")]
    @State private var isLoading = true
    @State private var isRefreshing = false
    @State private var errorMessage: String?
    @State private var isLoadingCategories = false
    @State private var isConnected = NetworkMonitor.shared.isConnected
    @State private var hasMoreData = true
    @State private var isLoadingNextPage = false

    /// Rows fetched per page while online. There is no overall ceiling — the list
    /// keeps paging until the server returns a short page.
    private let pageSize: Int32 = 50
    /// Offline, only the query variant the prefetcher warmed exists in the Apollo
    /// cache, so we load that whole snapshot at once instead of paginating.
    private let offlineSnapshotLimit: Int32 = 500
    @State private var selectedCityId: String? = nil
    /// Memoized result of filtering + distance sorting. See recomputeDisplayedLocations().
    @State private var displayedLocations: [Location] = []

    private var isFilteringCategory: Bool {
        selectedCategory != String(localized: "All Locations")
    }

    /// Distinct cities present in the loaded locations, so the filter only offers
    /// cities that actually have content. Client-side, so it works offline.
    private var availableCities: [LocationCity] {
        var seen = Set<String>()
        var result: [LocationCity] = []
        for location in locations {
            if let city = location.city, !seen.contains(city.id) {
                seen.insert(city.id)
                result.append(city)
            }
        }
        return result.sorted { $0.displayName < $1.displayName }
    }

    private var cityOptions: [FilterMenuOption] {
        [FilterMenuOption(id: nil, label: String(localized: "All Regions"))]
            + availableCities.map { FilterMenuOption(id: $0.id, label: $0.displayName) }
    }

    private var categoryOptions: [FilterMenuOption] {
        categories.map { name in
            FilterMenuOption(id: name == String(localized: "All Locations") ? nil : name, label: name)
        }
    }

    private var emptyStateTitle: String {
        if isFilteringCategory || selectedCityId != nil {
            return String(localized: "No Locations Found")
        }
        return String(localized: "No Locations Yet")
    }

    private var emptyStateMessage: String {
        if isFilteringCategory || selectedCityId != nil {
            return String(localized: "There are no locations for this filter yet.\nCheck back soon!")
        }
        return String(localized: "There are no locations in this city yet.\nCheck back soon!")
    }

    /// Buckets the user location to ~100 m. Used as the recompute trigger so the list
    /// re-orders when the user actually moves, not on every GPS jitter tick.
    private var userLocationBucket: String? {
        guard let coordinate = locationManager.userLocation else { return nil }
        return "\(Int(coordinate.latitude * 1000)),\(Int(coordinate.longitude * 1000))"
    }

    /// Filters and distance-sorts once per input change, into `displayedLocations`.
    ///
    /// This used to be a computed property, which SwiftUI re-evaluated on every body
    /// pass *and* inside each row's `onAppear` — so scrolling a 500-item list ran the
    /// filter+sort hundreds of times. The sort also allocated two `CLLocation`s per
    /// comparison (~9k allocations per pass); distances are now computed once per item.
    private func recomputeDisplayedLocations() {
        var result = locations

        if let cityId = selectedCityId {
            result = result.filter { $0.city?.id == cityId }
        }

        let allLocationsLabel = String(localized: "All Locations")
        if selectedCategory != allLocationsLabel {
            result = result.filter { $0.category?.displayName == selectedCategory }
        }

        if let userCoordinate = locationManager.userLocation {
            let userLoc = CLLocation(latitude: userCoordinate.latitude, longitude: userCoordinate.longitude)
            result = result
                .map { location -> (location: Location, distance: CLLocationDistance) in
                    let candidate = CLLocation(latitude: location.latitude, longitude: location.longitude)
                    return (location, candidate.distance(from: userLoc))
                }
                .sorted { $0.distance < $1.distance }
                .map(\.location)
        }

        displayedLocations = result
    }

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 24) {
                    CarouselListEvent(
                        title: "Upcoming events",
                        subtitle: "Top events",
                        showShowAllButton: false,
                        isBoostedOnly: true,
                        bottomPadding: 8
                    )
                    
                    AdsCarousel()

                    HStack(spacing: 8) {
                        InlineFilterChip(
                            icon: "mappin.and.ellipse",
                            title: "Regions",
                            options: cityOptions,
                            selectedId: selectedCityId
                        ) { selectedCityId = $0 }

                        Spacer()

                        InlineFilterChip(
                            icon: "slider.horizontal.3",
                            title: "Filter",
                            options: categoryOptions,
                            selectedId: selectedCategory == String(localized: "All Locations") ? nil : selectedCategory
                        ) { selectedCategory = $0 ?? String(localized: "All Locations") }
                    }
                    .padding(.horizontal, 16)
                    
                    if isLoading {
                        VStack(spacing: 12) {
                            ForEach(0..<6, id: \.self) { _ in
                                LocationItemSkeleton()
                            }
                        }
                        .padding(.horizontal, 16)
                    } else if let error = errorMessage {
                        VStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.title)
                                .foregroundStyle(.red)
                            Text(error)
                                .font(.subheadline)
                                .multilineTextAlignment(.center)
                            Button("Try Again") {
                                Task { await loadData() }
                            }
                            .buttonStyle(.bordered)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                        .padding(.horizontal)
                    } else if displayedLocations.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "mappin.slash")
                                .font(.system(size: 60))
                                .foregroundStyle(.secondary)
                            
                            Text(emptyStateTitle)
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            Text(emptyStateMessage)
                                .font(.body)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(displayedLocations) { location in
                                NavigationLink {
                                    LocationDetailView(location: location)
                                } label: {
                                    LocationItem(location: location)
                                        .background(
                                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                                .fill(Color(.secondarySystemBackground))
                                        )
                                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                }
                                .buttonStyle(.plain)
                                .onAppear {
                                    // Detect when user hits the bottom of the vertical list.
                                    if location.id == displayedLocations.last?.id {
                                        Task { await loadNextPage() }
                                    }
                                }
                                .simultaneousGesture(TapGesture().onEnded {
                                    FirebaseUtils.trackButtonTap(
                                        buttonName: "location_item",
                                        screenName: "AllLocations"
                                    )
                                })
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 24)
                    }
                }
                .padding(.top, 12)
            }
            .refreshable {
                await refreshFromNetwork()
            }
        }
        .navigationTitle("Locations")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                SettingsButton()
            }
        }
        .task {
            locationManager.requestPermission()
            locationManager.startUpdatingLocation()
            await loadData()
        }
        .onReceive(NotificationCenter.default.publisher(for: .networkStatusChanged)) { notification in
            guard let isConnected = notification.userInfo?["isConnected"] as? Bool else { return }
            self.isConnected = isConnected
        }
        .onChange(of: isConnected) { _, newValue in
            guard newValue else { return }
            Task { await refreshFromNetwork() }
        }
        // Recompute the filtered/sorted list only when an input actually changes,
        // instead of on every body pass.
        .onChange(of: selectedCityId) { _, _ in recomputeDisplayedLocations() }
        .onChange(of: selectedCategory) { _, _ in recomputeDisplayedLocations() }
        .onChange(of: userLocationBucket) { _, _ in recomputeDisplayedLocations() }
    }

    private func loadData(forceRefresh: Bool = false) async {
        if locations.isEmpty {
            isLoading = true
        }
        isLoadingCategories = true
        errorMessage = nil
        
        let previousLocations = locations
        let previousCategories = categories
        
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await loadLocations(forceRefresh: forceRefresh) }
            group.addTask { await loadLocationCategories() }
        }
        
        if locations.isEmpty && !previousLocations.isEmpty {
            locations = previousLocations
        }
        
        if categories.count == 1 && previousCategories.count > 1 {
            categories = previousCategories
        }
        
        // Final offline fallback: if categories are still only "All Locations" but we have locations,
        // rebuild categories from locations to enable offline filtering.
        if categories.count == 1, !locations.isEmpty {
            let derived = Array(Set(locations.compactMap { $0.category?.displayName })).sorted()
            if !derived.isEmpty {
                categories = [String(localized: "All Locations")] + derived
            }
        }
        
        isLoading = false
        isLoadingCategories = false

        // Single funnel point after locations + categories settle (initial load,
        // refresh, and the offline fallback assignment above).
        recomputeDisplayedLocations()
    }

    private func loadLocationCategories() async {
        // 1) Try cache-only first
        if let cached = await LocationCategoryService.shared.fetchLocationCategoriesFromCache(),
           !cached.isEmpty {
            let names = Array(Set(cached.map { $0.displayName })).sorted()
            categories = [String(localized: "All Locations")] + names
            return
        }
        
        // 2) Fall back to network (cacheFirst), then derive from locations
        do {
            let fetched = try await LocationCategoryService.shared.fetchLocationCategories()
            let names = Array(Set(fetched.map { $0.displayName })).sorted()
            categories = [String(localized: "All Locations")] + names
        } catch {
            let derived = Array(Set(locations.compactMap { $0.category?.displayName })).sorted()
            categories = [String(localized: "All Locations")] + derived
        }
    }
    
    /// Loads the first page (or, offline, the whole prefetched snapshot).
    private func loadLocations(forceRefresh: Bool = false) async {
        errorMessage = nil

        do {
            let limit = isConnected ? pageSize : offlineSnapshotLimit

            let fetchedLocations = try await LocationService.shared.fetchLocations(
                cityId: nil,
                limit: limit,
                offset: 0,
                forceRefresh: forceRefresh
            )

            self.locations = fetchedLocations
            // A full page means there may be more; a short page means we reached the end.
            // Offline there is nothing more to page through.
            hasMoreData = isConnected && fetchedLocations.count >= Int(limit)
        } catch {
            if locations.isEmpty {
                errorMessage = error.localizedDescription
            }
        }

        isLoading = false
    }

    /// Appends the next page when the user reaches the bottom of the list.
    private func loadNextPage() async {
        guard isConnected, hasMoreData, !isLoadingNextPage, !isLoading, !isRefreshing else { return }
        isLoadingNextPage = true
        defer { isLoadingNextPage = false }

        do {
            let fetched = try await LocationService.shared.fetchLocations(
                cityId: nil,
                limit: pageSize,
                offset: Int32(locations.count)
            )

            // Guard against duplicates in case rows shifted between page requests.
            var seen = Set(locations.map(\.id))
            let newItems = fetched.filter { seen.insert($0.id).inserted }
            locations.append(contentsOf: newItems)

            hasMoreData = fetched.count >= Int(pageSize)
            recomputeDisplayedLocations()
        } catch {
            // Keep what we have; scrolling to the bottom again retries.
        }
    }

    private func refreshFromNetwork() async {
        guard !isRefreshing else { return }
        isRefreshing = true
        defer { isRefreshing = false }
        await loadData(forceRefresh: true)
    }
}

#Preview {
    AllLocationListView()
}
