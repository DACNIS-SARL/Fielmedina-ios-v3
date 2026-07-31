//
//  AllTopPicks.swift
//  Fielmedina
//
//  Created by Aslan on 4/5/2026.
//
//  UI only. State and logic live in `AllMerchantsModel` — see `AllLocationsModel`
//  for the reasoning behind this pattern.
//

import SwiftUI
import CoreLocation

struct AllMerchants: View {
    /// Held with @State so it is created once and survives body re-evaluation,
    /// the SwiftUI equivalent of an Android ViewModel.
    @State private var model = AllMerchantsModel()
    @State private var locationManager = LocationManager()
    @State private var showFilterSheet = false
    @State private var carouselRefreshTrigger: Int = 0

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

                    if model.isLoading {
                        VStack(spacing: 12) {
                            ForEach(0..<6, id: \.self) { _ in
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(height: 100)
                            }
                        }
                        .padding(.horizontal, 16)
                    } else if let error = model.errorMessage {
                        VStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.title)
                                .foregroundStyle(.red)
                            Text(error)
                                .font(.subheadline)
                                .multilineTextAlignment(.center)
                            Button("Try Again") {
                                Task { await model.loadData() }
                            }
                            .buttonStyle(.bordered)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                        .padding(.horizontal)
                    } else if model.displayedMerchants.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "storefront")
                                .font(.system(size: 60))
                                .foregroundStyle(.secondary)

                            Text(model.emptyStateTitle)
                                .font(.title2)
                                .fontWeight(.semibold)

                            Text(model.emptyStateMessage)
                                .font(.body)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(model.displayedMerchants) { merchant in
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
                                .task(id: model.merchants.count) {
                                    // Near the bottom — pull the next page. Keyed on the RAW
                                    // loaded count, not the filtered list: a page may add no
                                    // rows matching the active filter, and keying on the
                                    // filtered list would leave the trigger stuck while more
                                    // pages still exist.
                                    if model.isNearEnd(merchant) {
                                        await model.loadNextPage()
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
                carouselRefreshTrigger += 1
                await model.refreshFromNetwork()
            }
        }
        .navigationTitle("Our Picks")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                SettingsButton()
            }
        }
        .sheet(isPresented: $showFilterSheet) {
            MerchantCategoryFilterView(
                availableCategories: model.categories,
                currentSelection: model.selectedCategory,
                isPresented: $showFilterSheet
            ) { model.selectedCategory = $0 }
        }
        .task {
            locationManager.requestPermission()
            locationManager.startUpdatingLocation()
            await model.loadData()
        }
        // The View owns CoreLocation permission/lifecycle and feeds the coordinate in;
        // the model buckets it so it only re-sorts on real movement.
        .onChange(of: locationManager.userLocation?.latitude) { _, _ in
            model.updateUserLocation(locationManager.userLocation)
        }
        .onChange(of: locationManager.userLocation?.longitude) { _, _ in
            model.updateUserLocation(locationManager.userLocation)
        }
    }
}

struct MerchantCategoryFilterView: View {
    /// Read-only inputs plus a callback — the model owns the state, so this sheet
    /// no longer needs write access via @Binding.
    let availableCategories: [String]
    let currentSelection: String
    @Binding var isPresented: Bool
    var onSelect: (String) -> Void

    var body: some View {
        NavigationStack {
            List {
                ForEach(availableCategories, id: \.self) { category in
                    Button {
                        onSelect(category)
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
