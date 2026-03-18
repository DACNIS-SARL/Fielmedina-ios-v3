//
//  CarouselListLocations.swift
//  Fielmedina
//
//  Created by Aslan on 1/16/26.
//

import SwiftUI

struct CarouselListLocations: View {
    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey?
    let showShowAllButton: Bool
    let limit: Int
    
    @Environment(\.scenePhase) private var scenePhase
    @State private var locations: [Location] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var currentCityId = CitySelectionStore.shared.cityId
    
    init(
        title: LocalizedStringKey,
        subtitle: LocalizedStringKey? = nil,
        showShowAllButton: Bool = true,
        limit: Int = 10
    ) {
        self.title = title
        self.subtitle = subtitle
        self.showShowAllButton = showShowAllButton
        self.limit = limit
    }
    
    var displayedLocations: [Location] {
        Array(locations.prefix(limit))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.title2)
                        .bold()
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                if showShowAllButton && !isLoading {
                    NavigationLink(value: HomeNavigationDestination.allLocations) {
                        Text("Show All")
                            .font(.system(size: 16, weight: .semibold))
                            .padding(.horizontal, 18)
                            .padding(.vertical, 12)
                            .background(.ultraThinMaterial)
                            .clipShape(Capsule())
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("show_all_locations_button")
                    .sensoryFeedback(.impact(weight: .light), trigger: isLoading)
                }
            }
            .padding(.horizontal)
            
            if isLoading {
                HStack(spacing: 16) {
                    ForEach(0..<3, id: \.self) { _ in
                        LocationCardSkeleton()
                    }
                }
                .padding(.horizontal)
            } else if let error = errorMessage {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 40))
                        .foregroundStyle(.red)
                    Text(error)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Button("Retry") {
                        Task { await loadLocations() }
                    }
                    .buttonStyle(.bordered)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else if displayedLocations.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "mappin.slash")
                        .font(.system(size: 40))
                        .foregroundStyle(.secondary)
                    Text("No locations available")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(displayedLocations) { location in
                            NavigationLink {
                                LocationDetailView(location: location)
                            } label: {
                                LocationCardView(location: location)
                            }
                            .buttonStyle(.plain)
                            .simultaneousGesture(TapGesture().onEnded {
                                FirebaseUtils.trackButtonTap(
                                    buttonName: "location_card_\(title)",
                                    screenName: "Home"
                                )
                            })
                        }
                    }
                    .padding(.horizontal)
                }
                .scrollClipDisabled()
                .transition(.opacity.animation(.easeIn(duration: 0.3)))
            }
        }
        .animation(.easeIn(duration: 0.3), value: isLoading)
        .task {
            await loadLocations()
        }
        .refreshable {
            await loadLocations(forceRefresh: true)
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                Task { await loadLocations(forceRefresh: true) }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .cityDidChange)) { notification in
            guard let newCityId = notification.object as? Int32 else { return }
            currentCityId = newCityId
        }
        .onChange(of: currentCityId) { _, _ in
            Task { await loadLocations() }
        }
    }
    
    private func loadLocations(forceRefresh: Bool = false) async {
        // Only show loading skeleton on first load, not on refresh
        if locations.isEmpty { isLoading = true }
        errorMessage = nil

        do {
            locations = try await LocationService.shared.fetchLocations(
                cityId: CitySelectionStore.shared.cityId,
                limit: Int32(limit),
                forceRefresh: forceRefresh
            )
        } catch {
            if locations.isEmpty {
                errorMessage = error.localizedDescription
            }
        }
        
        isLoading = false
    }
}
#Preview {
    NavigationStack {
        ScrollView {
            VStack(spacing: 32) {
                CarouselListLocations(
                    title: "Top Attractions",
                    subtitle: "Top 10 places for you"
                )
            }
        }
    }
}



extension Location {
    static let sampleLocations: [Location] = [
        Location(
            id: "1",
            nameEn: "Ribat of Sousse",
            nameFr: "Ribat de Sousse",
            latitude: 35.8256,
            longitude: 10.6369,
            category: LocationCategory(
                id: "1",
                nameEn: "Historical Site",
                nameFr: "Site Historique"
            ),
            images: nil,
            openFrom: "09:00",
            openTo: "16:00",
            storyEn: "A historic fortress built in the 8th century",
            storyFr: "Une forteresse historique construite au 8ème siècle",
            admissionFee: "8.00",
            closedDays: nil
        ),
        Location(
            id: "2",
            nameEn: "Great Mosque of Kairouan Great Mosque of Kairouan",
            nameFr: "Grande Mosquée de Kairouan Great Mosque of Kairouan",
            latitude: 35.6781,
            longitude: 10.1042,
            category: LocationCategory(
                id: "2",
                nameEn: "Religious Site",
                nameFr: "Site Religieux"
            ),
            images: nil,
            openFrom: "08:00",
            openTo: "17:30",
            storyEn: "One of the most important mosques in Tunisia",
            storyFr: "L'une des mosquées les plus importantes de Tunisie",
            admissionFee: "0",
            closedDays: nil
        )
    ]
}
