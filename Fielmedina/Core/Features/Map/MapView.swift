//
//  MapView.swift
//  Fielmedina
//
//  Created by Aslan on 1/8/26.
//

import SwiftUI
import MapboxMaps

struct MapView: View {
    private struct MedinaLocation: Identifiable {
        let id = UUID()
        let name: String
        let coordinate: CLLocationCoordinate2D
    }

    @Environment(\.colorScheme) private var colorScheme
    @State private var locationManager = LocationManager()
    @State private var viewport: Viewport = .camera(
        center: CLLocationCoordinate2D(
            latitude: 35.825892,
            longitude: 10.637448
        ),
        zoom: 15,
        bearing: 0,
        pitch: 40
    )
    @State private var showLocationAlert = false
    @State private var locations: [Location] = []
    @State private var selectedLocation: Location?
    @State private var showLocationDetail = false
    @State private var showFilterSheet = false
    @State private var selectedCategoryIds: Set<String> = []
    @State private var didCenterOnMedina = false

    private var standardLightPreset: StandardLightPreset {
        colorScheme == .light ? .day : .night
    }

    private let medinaRegistry: [MedinaLocation] = [
        MedinaLocation(name: "Sousse", coordinate: CLLocationCoordinate2D(latitude: 35.825892, longitude: 10.637448)),
        MedinaLocation(name: "Monastir", coordinate: CLLocationCoordinate2D(latitude: 35.7780, longitude: 10.8262)),
        MedinaLocation(name: "Tunis", coordinate: CLLocationCoordinate2D(latitude: 36.7992, longitude: 10.1706))
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Map(viewport: $viewport) {
                    Puck2D(bearing: .heading)

                    PointAnnotationGroup(filteredLocations, id: \.id) { location in
                        var annotation = PointAnnotation(coordinate: CLLocationCoordinate2D(
                            latitude: location.latitude,
                            longitude: location.longitude
                        ))
                        annotation = annotation
                            .image(named: markerName(for: location))
                            .iconAnchor(.bottom)
                            .iconSize(0.25)
                        annotation.tapHandler = { _ in
                            selectedLocation = location
                            showLocationDetail = true
                            return true
                        }
                        return annotation
                    }
                }
                .mapStyle(.standard(lightPreset: standardLightPreset))
                .ignoresSafeArea()
                
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        locationButton
                    }
                    .safeAreaPadding(.trailing)
                    .padding(.bottom, 50)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
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
                ToolbarItem(placement: .topBarTrailing) {
                    SettingsButton()
                }
            }
            .toolbarBackground(.visible, for: .navigationBar)
            .navigationDestination(isPresented: $showLocationDetail) {
                if let selectedLocation {
                    LocationDetailView(location: selectedLocation)
                }
            }
            .onAppear {
                locationManager.requestPermission()
                locationManager.startUpdatingLocation()
            }
            .task {
                await loadLocations()
                centerMapOnNearestMedinaIfNeeded()
            }
            .sheet(isPresented: $showFilterSheet) {
                MapFilterSheet(
                    categories: availableCategories,
                    selectedCategoryIds: $selectedCategoryIds
                )
                .presentationDetents([.medium, .large])
            }
            .alert("Location Access Required", isPresented: $showLocationAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                    FirebaseUtils.trackButtonTap(buttonName: "open_location_settings", screenName: "Map")
                }
            } message: {
                Text("To use this feature, please enable location access in Settings. Tap 'Location' and select 'While Using the App'.")
            }
            .onChange(of: locationManager.userLocation) { _, _ in
                centerMapOnNearestMedinaIfNeeded()
            }
        }
    }

    private func loadLocations() async {
        do {
            locations = try await LocationService.shared.fetchLocations(limit: 200)
            if selectedCategoryIds.isEmpty {
                selectedCategoryIds = Set(availableCategories.map { $0.id })
            }
        } catch {
            locations = []
        }
    }

    private func centerMapOnNearestMedinaIfNeeded() {
        guard !didCenterOnMedina,
              let userCoordinate = locationManager.userLocation else {
            return
        }

        let userLocation = CLLocation(latitude: userCoordinate.latitude, longitude: userCoordinate.longitude)
        guard let nearestMedina = medinaRegistry.min(by: { first, second in
            let firstDistance = userLocation.distance(from: CLLocation(latitude: first.coordinate.latitude, longitude: first.coordinate.longitude))
            let secondDistance = userLocation.distance(from: CLLocation(latitude: second.coordinate.latitude, longitude: second.coordinate.longitude))
            return firstDistance < secondDistance
        }) else {
            return
        }

        didCenterOnMedina = true
        withViewportAnimation(.default(maxDuration: 1.5)) {
            viewport = .camera(
                center: nearestMedina.coordinate,
                zoom: 15,
                bearing: 0,
                pitch: 40
            )
        }
    }

    private var filteredLocations: [Location] {
        guard !selectedCategoryIds.isEmpty else { return locations }
        return locations.filter { location in
            guard let categoryId = location.category?.id else { return false }
            return selectedCategoryIds.contains(categoryId)
        }
    }

    private var availableCategories: [LocationCategory] {
        var seen = Set<String>()
        let categories = locations.compactMap { $0.category }.filter { category in
            if seen.contains(category.id) { return false }
            seen.insert(category.id)
            return true
        }
        return categories.sorted { $0.displayName < $1.displayName }
    }
    
    @ViewBuilder
    private var locationButton: some View {
        if locationManager.authorizationStatus == .authorizedWhenInUse ||
           locationManager.authorizationStatus == .authorizedAlways {
            Button(action: {
                withViewportAnimation(.default(maxDuration: 1)) {
                    viewport = .followPuck(zoom: 18, bearing: .heading, pitch: 40)
                }
                FirebaseUtils.trackButtonTap(buttonName: "center_on_user_location", screenName: "Map")
            }) {
                Image(systemName: "location.fill")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.accentColor)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
            }
        } else if locationManager.authorizationStatus == .denied ||
                  locationManager.authorizationStatus == .restricted {
            Button(action: {
                showLocationAlert = true
                FirebaseUtils.trackButtonTap(buttonName: "request_location_settings", screenName: "Map")
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "location.slash.fill")
                        .font(.system(size: 16, weight: .medium))
                    Text("Enable location")
                        .font(.system(size: 14, weight: .medium))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.accentColor)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
            }
        } else {
            Button(action: {
                locationManager.requestPermission()
                FirebaseUtils.trackButtonTap(buttonName: "request_location_permission", screenName: "Map")
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 16, weight: .medium))
                    Text("Enable location")
                        .font(.system(size: 14, weight: .medium))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.accentColor)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
            }
        }
    }

    private func markerName(for location: Location) -> String {
        if let categoryId = location.category?.id, let marker = markerNamesById[categoryId] {
            return marker
        }
        let categoryName = (location.category?.nameEn ?? location.category?.nameFr ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        return markerNamesByName[categoryName] ?? "location-marker"
    }

    private var markerNamesById: [String: String] {
        [
            "1": "location-marker",
            "2": "moaque-marker",
            "3": "museum-marker",
            "4": "handcrafts-marker",
            "5": "restaurant-marker",
            "6": "coffee-shop-marker",
            "7": "gest-house-marker",
            "8": "medina-gate-marker",
            "9": "hotel-marker",
            "10": "arch-site-marker",
            "11": "monument-marker",
            "12": "market-marker",
            "13": "zaouia-marker"
        ]
    }

    private var markerNamesByName: [String: String] {
        [
            "location": "location-marker",
            "mosque": "moaque-marker",
            "museum": "museum-marker",
            "handicrafts": "handcrafts-marker",
            "restaurant": "restaurant-marker",
            "coffee shop": "coffee-shop-marker",
            "guest house": "gest-house-marker",
            "medina gate": "medina-gate-marker",
            "hotel": "hotel-marker",
            "archaeological site": "arch-site-marker",
            "monument": "monument-marker",
            "souk / market": "market-marker",
            "souk/market": "market-marker",
            "market": "market-marker",
            "souk": "market-marker",
            "zaouia": "zaouia-marker"
        ]
    }
}

#Preview {
    MapView()
}
