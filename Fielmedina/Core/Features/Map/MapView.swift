//
//  MapView.swift
//  Fielmedina
//
//  Created by Aslan on 1/8/26.
//

import SwiftUI
import MapboxMaps

struct MapView: View {
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
    /// Held with @State so it is created once and survives body re-evaluation,
    /// the SwiftUI equivalent of an Android ViewModel. Camera/viewport state stays
    /// in the View — that's renderer state, not app data.
    @State private var model = MapContentModel()
    @State private var selectedLocation: Location?
    @State private var showLocationDetail = false
    @State private var showFilterSheet = false
    @State private var didCenterOnMedina = false
    @State private var shouldShowCityDownloadPrompt = false

    private var standardLightPreset: StandardLightPreset {
        colorScheme == .light ? .day : .night
    }

    var body: some View {
        NavigationStack {
            ZStack {
                MapReader { proxy in
                Map(viewport: $viewport) {
                    Puck2D(bearing: .heading)

                    PointAnnotationGroup(model.displayedLocations, id: \.id) { location in
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
                // Landmark models can only be installed once the style exists. This
                // stays above `ignoresSafeArea()` because `onStyleLoaded` is a method
                // on `Map` itself, not on `some View`.
                .onStyleLoaded { _ in applyLandmarkModels(proxy) }
                .ignoresSafeArea()
                // Re-apply whenever the displayed set changes (category filter) or a
                // prefetch lands a newly downloaded .glb.
                .onChange(of: model.displayedLocations) { _, _ in applyLandmarkModels(proxy) }
                .onReceive(NotificationCenter.default.publisher(for: .offlinePrefetchCompleted)) { _ in
                    applyLandmarkModels(proxy)
                }
                }


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
                await model.loadData()
                centerMapOnNearestMedinaIfNeeded()
            }
            .onReceive(NotificationCenter.default.publisher(for: .offlineCityDataMissing)) { _ in
                shouldShowCityDownloadPrompt = true
            }
            .sheet(isPresented: $showFilterSheet) {
                MapFilterSheet(
                    categories: model.locationCategories,
                    selectedCategoryIds: $model.selectedCategoryIds
                )
                .presentationDetents([.medium, .large])
            }
            .alert(String(localized: "Offline city data unavailable"), isPresented: $shouldShowCityDownloadPrompt) {
                Button(String(localized: "OK"), role: .cancel) { }
            } message: {
                Text(String(localized: "You're offline. Connect to download data for this city."))
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

    /// Installs the 3D landmark models for whatever is currently displayed.
    ///
    /// Cheap when nothing qualifies: `placements(from:)` filters out every location
    /// without a downloaded `.glb`, which today is nearly all of them.
    private func applyLandmarkModels(_ proxy: MapProxy) {
        guard let mapboxMap = proxy.map else { return }
        let placements = LandmarkModelLayers.placements(from: model.displayedLocations)
        LandmarkModelLayers.apply(placements: placements, to: mapboxMap)
    }

    /// Centres on whichever medina is closest to the user, once, on the first fix.
    ///
    /// The candidate list comes from `OfflineCityDataStore` — the same server-driven
    /// cache the offline downloads and navigation guards use — so a city added in the
    /// backend is picked up on the next launch without an app update. This used to be
    /// a hardcoded three-city list local to this view, which meant every new region
    /// was invisible to the camera.
    private func centerMapOnNearestMedinaIfNeeded() {
        guard !didCenterOnMedina,
              let userCoordinate = locationManager.userLocation,
              let nearestMedina = OfflineCityDataStore.shared.nearestCity(to: userCoordinate) else {
            return
        }

        didCenterOnMedina = true
        withViewportAnimation(.default(maxDuration: 1.5)) {
            viewport = .camera(
                center: CLLocationCoordinate2D(
                    latitude: nearestMedina.latitude,
                    longitude: nearestMedina.longitude
                ),
                zoom: 15,
                bearing: 0,
                pitch: 40
            )
        }
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
