//
//  AllLocationList.swift
//  Fielmedina
//
//  Created by Aslan on 1/16/26.
//

import SwiftUI

struct AllLocationListView: View {
    @State private var locations: [Location] = []
    @State private var selectedCategory: String = String(localized: "All Locations")
    @State private var showFilterSheet = false
    @State private var categories: [String] = [String(localized: "All Locations")]
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    var filteredLocations: [Location] {
        if selectedCategory == String(localized: "All Locations") {
            return locations
        } else {
            return locations.filter { $0.category?.displayName == selectedCategory }
        }
    }
    
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    CarouselListEvent(
                        title: "Upcoming events",
                        subtitle: "Top events",
                        showShowAllButton: false,
                        isBoostedOnly: true,
                        bottomPadding: 8
                    )
                    
                    AdsCarousel()

                    HStack {
                        Text("ALL LOCATIONS")
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
                        VStack {
                            ProgressView("Loading locations...")
                                .padding(.vertical, 40)
                        }
                        .frame(maxWidth: .infinity)
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
                            
                            Text("No Locations Found")
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            Text("There are no locations in this category yet.\nCheck back soon!")
                                .font(.body)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    } else {
                        VStack(spacing: 12) {
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
        }
        .navigationTitle("Locations")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                SettingsButton()
            }
        }
        .sheet(isPresented: $showFilterSheet) {
            LocationCategoryFilterView(
                availableCategories: $categories,
                currentSelection: $selectedCategory,
                isPresented: $showFilterSheet
            )
        }
        .task {
            await loadData()
        }
    }
    
    private func loadData() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let fetchedLocations = try await LocationService.shared.fetchLocations(limit: 50)
            self.locations = fetchedLocations
            
            // Extract unique categories
            let uniqueCategories = Set(fetchedLocations.compactMap { $0.category?.displayName })
            categories = [String(localized: "All Locations")] + uniqueCategories.sorted()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
}

struct LocationCategoryFilterView: View {
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
                            screenName: "AllLocations"
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
    AllLocationListView()
}
