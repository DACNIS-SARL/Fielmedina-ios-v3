//
//  CarouselListLocations.swift
//  Fielmedina
//
//  Created by Aslan on 1/16/26.
//

import SwiftUI
import CoreLocation

struct CarouselListLocations: View {
    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey?
    let showShowAllButton: Bool
    let limit: Int
    
    @Environment(\.scenePhase) private var scenePhase
    @State private var locations: [Location] = []
    @State private var isLoading = true
    @State private var isRefreshing = false
    @State private var isHorizontalRefreshing = false
    @State private var errorMessage: String?
    @Binding var refreshTrigger: Int
    
    init(
        title: LocalizedStringKey,
        subtitle: LocalizedStringKey? = nil,
        showShowAllButton: Bool = true,
        limit: Int = 10,
        refreshTrigger: Binding<Int> = .constant(0)
    ) {
        self.title = title
        self.subtitle = subtitle
        self.showShowAllButton = showShowAllButton
        self.limit = limit
        self._refreshTrigger = refreshTrigger
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
                        if isHorizontalRefreshing {
                            ProgressView()
                                .padding(.leading, 16)
                                .transition(.scale)
                        }
                        
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
                .onScrollGeometryChange(for: CGFloat.self, of: { geo in
                    return geo.contentOffset.x
                }, action: { oldValue, newValue in
                    let threshold: CGFloat = 100
                    if newValue < -threshold && !isRefreshing && !isHorizontalRefreshing {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        isHorizontalRefreshing = true
                        Task {
                            await loadLocations(forceRefresh: true)
                            isHorizontalRefreshing = false
                        }
                    }
                })
                .clipped()
                .transition(.opacity.animation(.easeIn(duration: 0.3)))
            }
        }
        .animation(.easeIn(duration: 0.3), value: isLoading)
        .task {
            await loadLocations()
        }

        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                Task { await loadLocations(forceRefresh: true) }
            }
        }
        .onChange(of: refreshTrigger) { _, _ in
            Task { await loadLocations(forceRefresh: true) }
        }
        // Re-sort when the user location becomes available (mirrors Android's
        // remember(userLocation) recomputation). LocationManager is observable.
        .onChange(of: LocationManager.shared.userLocation?.latitude) { _, _ in
            self.locations = sortByDistance(self.locations, user: LocationManager.shared.userLocation)
        }
    }
    
    private func loadLocations(forceRefresh: Bool = false) async {
        if forceRefresh {
            isRefreshing = true
        } else {
            isLoading = true
        }
        defer {
            isLoading = false
            isRefreshing = false
        }
        
        do {
            // Match Android home: fetch a large pool of locations and pick the closest
            // `limit` to the user. Android sorts the full map location set, not a
            // server-truncated list, so fetching only `limit` here would never let us
            // surface the nearest places.
            let fetchedLocations = try await LocationService.shared.fetchLocations(
                cityId: nil,
                limit: 500,
                forceRefresh: forceRefresh
            )
            self.locations = sortByDistance(fetchedLocations, user: LocationManager.shared.userLocation)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    /// Mirrors Android `sortLocationsByDistance`: when no user location is available
    /// the server order is kept; (0,0) coordinates are pushed to the end.
    private func sortByDistance(_ locations: [Location],
                                user: CLLocationCoordinate2D?) -> [Location] {
        guard let user else { return locations }
        let origin = CLLocation(latitude: user.latitude, longitude: user.longitude)
        return locations.sorted { distance($0, from: origin) < distance($1, from: origin) }
    }
    
    private func distance(_ location: Location, from origin: CLLocation) -> CLLocationDistance {
        if location.latitude == 0 && location.longitude == 0 {
            return .greatestFiniteMagnitude
        }
        return CLLocation(latitude: location.latitude, longitude: location.longitude).distance(from: origin)
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
            city: nil,
            images: nil,
            openFrom: "09:00",
            openTo: "16:00",
            storyEn: "A historic fortress built in the 8th century",
            storyFr: "Une forteresse historique construite au 8ème siècle",
            admissionFee: "8.00",
            closedDays: nil,
            voiceoverEn: nil,
            voiceoverFr: nil
        ),
        Location(
            id: "2",
            nameEn: "Great Mosque of Kairouan",
            nameFr: "Grande Mosquée de Kairouan",
            latitude: 35.6781,
            longitude: 10.1042,
            category: LocationCategory(
                id: "2",
                nameEn: "Religious Site",
                nameFr: "Site Religieux"
            ),
            city: nil,
            images: nil,
            openFrom: "08:00",
            openTo: "17:30",
            storyEn: "One of the most important mosques in Tunisia",
            storyFr: "L'une des mosquées les plus importantes de Tunisie",
            admissionFee: "0",
            closedDays: nil,
            voiceoverEn: nil,
            voiceoverFr: nil
        )
    ]
}
