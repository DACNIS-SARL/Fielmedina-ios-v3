//
//  AllLocationList.swift
//  Fielmedina
//
//  Created by Aslan on 1/16/26.
//
//  UI only. All state and logic live in `AllLocationsModel` — see the notes there
//  for why (this is the reference pattern for the rest of the iOS screens).
//

import SwiftUI
import CoreLocation

struct AllLocationListView: View {
    /// Held with @State so it is created once and survives body re-evaluation,
    /// the SwiftUI equivalent of an Android ViewModel.
    @State private var model = AllLocationsModel()
    @State private var locationManager = LocationManager()

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
                            options: model.cityOptions,
                            selectedId: model.selectedCityId
                        ) { model.selectedCityId = $0 }

                        Spacer()

                        InlineFilterChip(
                            icon: "slider.horizontal.3",
                            title: "Filter",
                            options: model.categoryOptions,
                            selectedId: model.selectedCategoryId
                        ) { model.selectedCategoryId = $0 }
                    }
                    .padding(.horizontal, 16)

                    if model.isLoading {
                        VStack(spacing: 12) {
                            ForEach(0..<6, id: \.self) { _ in
                                LocationItemSkeleton()
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
                    } else if model.displayedLocations.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "mappin.slash")
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
                            ForEach(model.displayedLocations) { location in
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
                                .task(id: model.locations.count) {
                                    // Near the bottom — pull the next page. Keyed on the RAW
                                    // loaded count, not the filtered list: a page may add no
                                    // rows matching the active filter, and keying on the
                                    // filtered list would leave the trigger stuck while more
                                    // pages still exist.
                                    if model.isNearEnd(location) {
                                        model.loadNextPage()
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
                await model.refreshFromNetwork()
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

#Preview {
    AllLocationListView()
}
