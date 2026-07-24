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
    @State private var currentLimit: Int32 = 50
    @State private var hasMoreData = true
    @State private var carouselRefreshTrigger: Int = 0

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

    var filteredMerchants: [Merchant] {
        var result = merchants
        if selectedCategory != String(localized: "All Picks") {
            result = result.filter { $0.category?.displayName == selectedCategory }
        }

        if let userCoordinate = locationManager.userLocation {
            let userLoc = CLLocation(latitude: userCoordinate.latitude, longitude: userCoordinate.longitude)
            result.sort {
                let leftLat = $0.latitude ?? 0.0
                let leftLon = $0.longitude ?? 0.0
                let rightLat = $1.latitude ?? 0.0
                let rightLon = $1.longitude ?? 0.0
                
                let leftLoc = CLLocation(latitude: leftLat, longitude: leftLon)
                let rightLoc = CLLocation(latitude: rightLat, longitude: rightLon)
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
                    } else if filteredMerchants.isEmpty {
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
                            ForEach(filteredMerchants) { merchant in
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
                                .onAppear {
                                    // Skip pagination while searching — search filters the loaded set.
                                    if merchant.id == filteredMerchants.last?.id && !isLoading && !isRefreshing && hasMoreData {
                                        currentLimit += 50
                                        Task { await refreshFromNetwork() }
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
    }
    
    private func loadMerchants(forceRefresh: Bool = false) async {
        errorMessage = nil

        do {
            let effectiveLimit: Int32 = merchants.isEmpty ? 500 : (isConnected ? currentLimit : 500)
            
            if forceRefresh && merchants.isEmpty {
                 currentLimit = 50
                 hasMoreData = true
            }
            
            let fetchedMerchants = try await MerchantService.shared.fetchMerchants(
                cityId: nil,
                categoryId: nil,
                limit: effectiveLimit,
                forceRefresh: forceRefresh
            )
            
            if fetchedMerchants.count < effectiveLimit {
                hasMoreData = false
            } else {
                hasMoreData = isConnected
            }
            self.merchants = fetchedMerchants
            
        } catch {
            if merchants.isEmpty {
                errorMessage = error.localizedDescription
            }
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
