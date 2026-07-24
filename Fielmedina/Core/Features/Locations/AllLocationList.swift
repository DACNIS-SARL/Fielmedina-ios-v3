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
    @State private var currentLimit: Int32 = 50
    @State private var hasMoreData = true
    @State private var selectedCityId: String? = nil

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
        [FilterMenuOption(id: nil, label: String(localized: "All Cities"))]
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

    var filteredLocations: [Location] {
        var result = locations
        if let cityId = selectedCityId {
            result = result.filter { $0.city?.id == cityId }
        }
        if selectedCategory != String(localized: "All Locations") {
            result = result.filter { $0.category?.displayName == selectedCategory }
        }

        if let userCoordinate = locationManager.userLocation {
            let userLoc = CLLocation(latitude: userCoordinate.latitude, longitude: userCoordinate.longitude)
            result.sort {
                let leftLoc = CLLocation(latitude: $0.latitude, longitude: $0.longitude)
                let rightLoc = CLLocation(latitude: $1.latitude, longitude: $1.longitude)
                return leftLoc.distance(from: userLoc) < rightLoc.distance(from: userLoc)
            }
        }
        return result
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
                            options: cityOptions,
                            selectedId: selectedCityId
                        ) { selectedCityId = $0 }

                        Spacer(minLength: 4)

                        Text("LOCATIONS")
                            .font(.caption).bold()
                            .foregroundStyle(.secondary)

                        Spacer(minLength: 4)

                        InlineFilterChip(
                            icon: "line.3.horizontal.decrease",
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
                    } else if filteredLocations.isEmpty {
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
                            ForEach(filteredLocations) { location in
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
                                    if location.id == filteredLocations.last?.id && !isLoading && !isRefreshing && hasMoreData {
                                        currentLimit += 50
                                        Task { await refreshFromNetwork() }
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
    
    private func loadLocations(forceRefresh: Bool = false) async {
        errorMessage = nil

        do {
            // We always use 500 for the initial load to ensure we hit the same cache key
            // that the OfflineContentPrefetcher uses. 
            let effectiveLimit: Int32 = locations.isEmpty ? 500 : (isConnected ? currentLimit : 500)
            
            if forceRefresh && locations.isEmpty {
                 currentLimit = 50
                 hasMoreData = true
            }
            
            let fetchedLocations = try await LocationService.shared.fetchLocations(
                cityId: nil,
                limit: effectiveLimit,
                forceRefresh: forceRefresh
            )
            
            if fetchedLocations.count < effectiveLimit {
                hasMoreData = false
            } else {
                hasMoreData = isConnected // Only allow pagination when online
            }
            self.locations = fetchedLocations
            
            // Extract unique categories
            // Removed categories assignment here as per instructions
            
        } catch {
            if locations.isEmpty {
                errorMessage = error.localizedDescription
            }
        }
        
        isLoading = false
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
