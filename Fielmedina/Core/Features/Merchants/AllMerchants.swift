//
//  AllTopPicks.swift
//  Fielmedina
//
//  Created by Aslan on 4/5/2026.
//

import SwiftUI
import CoreLocation

struct AllMerchants: View {
    @State private var merchants: [Merchant] = []
    @State private var locationManager = LocationManager()
    @State private var selectedCategory: String = String(localized: "All Picks")
    @State private var showFilterSheet = false
    @State private var categories: [String] = [String(localized: "All Picks")]
    @State private var isLoading = true
    @State private var isRefreshing = false
    @State private var errorMessage: String?
    @State private var isConnected = NetworkMonitor.shared.isConnected
    @State private var hasMoreData = true
    @State private var isLoadingNextPage = false

    /// Rows fetched per page while online. No overall ceiling — paging continues
    /// until the server returns a short page.
    private let pageSize: Int32 = 50
    /// Offline, only the prefetcher's warmed query variant exists in the cache, so
    /// load that whole snapshot at once instead of paginating.
    private let offlineSnapshotLimit: Int32 = 200
    @State private var carouselRefreshTrigger: Int = 0
    /// Memoized result of filtering + distance sorting. See recomputeDisplayedMerchants().
    @State private var displayedMerchants: [Merchant] = []

    private var isFilteringCategory: Bool {
        selectedCategory != String(localized: "All Picks")
    }

    private var emptyStateTitle: String {
        if isFilteringCategory {
            return String(localized: "No Picks Found")
        }
        return String(localized: "No Picks Yet")
    }

    private var emptyStateMessage: String {
        if isFilteringCategory {
            return String(localized: "There are no picks in this category yet.\nCheck back soon!")
        }
        return String(localized: "There are no picks available yet.\nCheck back soon!")
    }

    /// Buckets the user location to ~100 m so the list only re-orders when the user
    /// actually moves, not on every GPS jitter tick.
    private var userLocationBucket: String? {
        guard let coordinate = locationManager.userLocation else { return nil }
        return "\(Int(coordinate.latitude * 1000)),\(Int(coordinate.longitude * 1000))"
    }

    /// Filters and distance-sorts once per input change, into `displayedMerchants`.
    /// Previously a computed property, so SwiftUI re-ran it on every body pass and
    /// inside each row's `onAppear`, allocating two `CLLocation`s per comparison.
    private func recomputeDisplayedMerchants() {
        var result = merchants

        let allPicksLabel = String(localized: "All Picks")
        if selectedCategory != allPicksLabel {
            result = result.filter { $0.category?.displayName == selectedCategory }
        }

        if let userCoordinate = locationManager.userLocation {
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

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 24) {
                    HeroBanner(imageName: "our-pick", showText: false)
                        .frame(maxWidth: .infinity)
                    
                    CarouselListMerchants(
                        title: "Top Picks Right Now",
                        isFeaturedOnly: true,
                        refreshTrigger: $carouselRefreshTrigger
                    )

                    HStack {
                        Text(String(localized: "ALL PICKS"))
                            .font(.caption).bold()
                            .foregroundStyle(.secondary)
                        
                        Spacer()
                        
                        Button {
                            showFilterSheet = true
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "slider.horizontal.3")
                                    .font(.system(size: 16, weight: .medium))
                                Text("Filter")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .padding(.horizontal, 18)
                            .padding(.vertical, 12)
                            .background(.ultraThinMaterial)
                            .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 16)
                    
                    if isLoading {
                        VStack(spacing: 12) {
                            ForEach(0..<6, id: \.self) { _ in
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(height: 100)
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
                    } else if displayedMerchants.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "storefront")
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
                            ForEach(displayedMerchants) { merchant in
                                NavigationLink {
                                    MerchantDetailView(merchant: merchant)
                                } label: {
                                    MerchantItem(merchant: merchant)
                                        .background(
                                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                                .fill(Color(.secondarySystemBackground))
                                        )
                                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                }
                                .buttonStyle(.plain)
                                .task(id: merchants.count) {
                                    // Bottom of the list — pull the next page. Keyed on the RAW
                                    // loaded count, not the filtered list: a page may add no rows
                                    // matching the active filter, and keying on the filtered list
                                    // would leave the trigger stuck while more pages still exist.
                                    if merchant.id == displayedMerchants.last?.id {
                                        await loadNextPage()
                                    }
                                }
                                .simultaneousGesture(TapGesture().onEnded {
                                    FirebaseUtils.trackButtonTap(
                                        buttonName: "merchant_item",
                                        screenName: "AllMerchants"
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
        .navigationTitle(String(localized: "Our Pick"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                SettingsButton()
            }
        }
        .sheet(isPresented: $showFilterSheet) {
            MerchantCategoryFilterView(
                availableCategories: $categories,
                currentSelection: $selectedCategory,
                isPresented: $showFilterSheet
            )
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
        // Recompute only when an input actually changes, not on every body pass.
        .onChange(of: selectedCategory) { _, _ in recomputeDisplayedMerchants() }
        .onChange(of: userLocationBucket) { _, _ in recomputeDisplayedMerchants() }
    }

    private func loadData(forceRefresh: Bool = false) async {
        if merchants.isEmpty {
            isLoading = true
        }
        errorMessage = nil
        
        let previousMerchants = merchants
        let previousCategories = categories
        
        await loadMerchants(forceRefresh: forceRefresh)
        
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
    
    /// Loads the first page (or, offline, the whole prefetched snapshot).
    private func loadMerchants(forceRefresh: Bool = false) async {
        errorMessage = nil

        do {
            let limit = isConnected ? pageSize : offlineSnapshotLimit

            let fetchedMerchants = try await MerchantService.shared.fetchMerchants(
                cityId: nil,
                categoryId: nil,
                limit: limit,
                offset: 0,
                forceRefresh: forceRefresh
            )

            self.merchants = fetchedMerchants
            hasMoreData = isConnected && fetchedMerchants.count >= Int(limit)
        } catch {
            if merchants.isEmpty {
                errorMessage = error.localizedDescription
            }
        }
    }

    /// Appends the next page when the user reaches the bottom of the list.
    private func loadNextPage() async {
        guard isConnected, hasMoreData, !isLoadingNextPage, !isLoading, !isRefreshing else { return }
        isLoadingNextPage = true
        defer { isLoadingNextPage = false }

        do {
            let fetched = try await MerchantService.shared.fetchMerchants(
                cityId: nil,
                categoryId: nil,
                limit: pageSize,
                offset: Int32(merchants.count)
            )
            var seen = Set(merchants.map(\.id))
            let newItems = fetched.filter { seen.insert($0.id).inserted }
            merchants.append(contentsOf: newItems)

            hasMoreData = fetched.count >= Int(pageSize)
            recomputeDisplayedMerchants()
        } catch {
            // Keep what we have; scrolling to the bottom again retries.
        }
    }

    private func refreshFromNetwork() async {
        guard !isRefreshing else { return }
        isRefreshing = true
        defer { isRefreshing = false }
        carouselRefreshTrigger += 1
        await loadData(forceRefresh: true)
    }
}

struct MerchantCategoryFilterView: View {
    @Binding var availableCategories: [String]
    @Binding var currentSelection: String
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(availableCategories, id: \.self) { category in
                    Button {
                        currentSelection = category
                        isPresented = false
                        
                        FirebaseUtils.trackButtonTap(
                            buttonName: "filter_\(category)",
                            screenName: "AllMerchants"
                        )
                    } label: {
                        HStack {
                            Text(category)
                                .font(.system(size: 16))
                                .foregroundStyle(.primary)
                            
                            Spacer()
                            
                            if currentSelection == category {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.primary)
                                    .font(.system(size: 16, weight: .semibold))
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)
                }
            }
            .navigationTitle("Filter by Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

#Preview {
    AllMerchants()
}
