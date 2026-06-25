//
//  LocationDetailView.swift
//  Fielmedina
//
//  Created by Aslan on 1/23/26.
//

import SwiftUI
import CoreLocation
import MapboxNavigationCore
import MapboxDirections

struct LocationDetailView: View {
    let location: Location
    
    @State private var selectedImageIndex: Int? = 0
    @State private var locationManager = LocationManager()
    private let mapboxNavigationProvider = MapboxNavigationProviderStore.shared
    @State private var navigationRoutes: NavigationRoutes?
    @State private var isNavigationPresented = false
    @State private var isNavigationLoading = false
    @State private var showLocationAlert = false
    @State private var showNavigationErrorAlert = false
    @State private var navigationErrorMessage = ""
    @State private var showARUnavailableAlert = false
    @State private var voiceoverPlayer = LocationVoiceoverPlayer()
    @State private var showDownloadRequiredAlert = false
    @State private var missingCityName = ""
    
    private var currentUserCoordinate: CLLocationCoordinate2D? {
        locationManager.userLocation
    }
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(alignment: .leading, spacing: 0) {
                HeroBanner(imageURL: location.imageURL, showText: false)
                    .frame(maxWidth: .infinity)
                
                detailsCard
            }
            .frame(maxWidth: .infinity)
        }
        .coordinateSpace(name: "scroll")
        .ignoresSafeArea(edges: .top)
        .ignoresSafeArea(edges: .horizontal)
        .navigationTitle(location.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                SettingsButton()
            }
        }
        .task {
            locationManager.requestPermission()
            locationManager.startUpdatingLocation()
        }
        .onDisappear {
            locationManager.stopUpdatingLocation()
            voiceoverPlayer.stop()
        }
        .fullScreenCover(isPresented: $isNavigationPresented) {
            NavigationCoverView(
                routes: $navigationRoutes,
                provider: mapboxNavigationProvider,
                locationName: location.displayName,
                userLocation: currentUserCoordinate,
                isLoading: $isNavigationLoading,
                onDismiss: {
                    navigationRoutes = nil
                    isNavigationPresented = false
                    isNavigationLoading = false
                }
            )
        }
        .alert("Location Access Required", isPresented: $showLocationAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
        } message: {
            Text("To start navigation, please enable location access in Settings. Tap 'Location' and select 'While Using the App'.")
        }
        .alert("Navigation Error", isPresented: $showNavigationErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(navigationErrorMessage)
        }
        .alert(String(localized: "AR not available"), isPresented: $showARUnavailableAlert) {
            Button(String(localized: "OK"), role: .cancel) { }
        } message: {
            Text(String(localized: "This location has no AR experience yet."))
        }
        .alert(String(localized: "Offline Map Required"), isPresented: $showDownloadRequiredAlert) {
            Button(String(localized: "OK"), role: .cancel) { }
        } message: {
            Text(String(format: String(localized: "You need to download the offline map for %@ Medina under Settings before starting navigation."), missingCityName))
        }
        .onAppear {
            FirebaseUtils.trackScreenView(screenName: "location_detail_\(location.displayName)", screenClass: "LocationDetailView")
        }
    }
    
    private var detailsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(location.displayName)
                .font(.title3)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
            
            HStack(spacing: 12) {
                Button {
                    FirebaseUtils.trackButtonTap(buttonName: "start_navigation_\(location.displayName)", screenName: "LocationDetailView")
                    startNavigation()
                } label: {
                    Label("Start Navigation", systemImage: "location.north.line")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color(red: 0.72, green: 0.41, blue: 0.25))
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                
                Button {
                    FirebaseUtils.trackButtonTap(buttonName: "open_ar_\(location.displayName)", screenName: "LocationDetailView")
                    showARUnavailableAlert = true
                } label: {
                    Image(systemName: "cube.transparent")
                        .font(.system(size: 22, weight: .semibold))
                        .frame(width: 52, height: 52)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 50, style: .continuous))
                }
                .buttonStyle(.plain)
            }
            
            imageCarousel
            
            AdsCarousel()
            
            if let category = location.category?.displayName {
                Text(category.uppercased())
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(red: 0.72, green: 0.41, blue: 0.25))
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
            }
            
            HStack(spacing: 16) {
                if let schedule = location.displaySchedule {
                    detailBadge(title: String(localized: "Opening Hours"), value: schedule, systemImage: "clock")
                }
                if let admission = location.displayAdmission {
                    detailBadge(title: String(localized: "Admission Fee"), value: "\(admission) TND", systemImage: "dollarsign.circle")
                }
                Spacer(minLength: 0)

                if location.hasVoiceover, let urlString = location.voiceoverURL {
                    Button {
                        FirebaseUtils.trackButtonTap(buttonName: "voiceover_listen_\(location.displayName)", screenName: "LocationDetailView")
                        voiceoverPlayer.toggle(remoteURLString: urlString)
                    } label: {
                        Image(systemName: voiceoverPlayer.isPlaying ? "stop.fill" : "speaker.wave.2.fill")
                            .font(.system(size: 18, weight: .bold))
                            .frame(width: 44, height: 44)
                            .background(Color(red: 0.72, green: 0.41, blue: 0.25))
                            .foregroundStyle(.white)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(String(localized: "Listen to audio guide"))
                }
            }
            if let story = location.displayStory {
                HTMLTextView(
                    html: story,
                    textStyle: .body,
                    textColor: .secondary
                )
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .padding(.horizontal, 0)
        .padding(.top, -24)
        .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 6)
    }
    private var imageCarousel: some View {
        let images = location.images ?? []
        
        return VStack(spacing: 10) {
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 12) {
                    ForEach(Array(images.enumerated()), id: \.offset) { index, image in
                        FielmedinaImage(url: image.displayURL, contentMode: .fill)
                            .containerRelativeFrame(.horizontal)
                            .aspectRatio(16/9, contentMode: .fill)
                            .frame(maxHeight: 450)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .scrollTransition(.animated, axis: .horizontal) { content, phase in
                                content
                                    .scaleEffect(phase.isIdentity ? 1 : 0.9)
                                    .blur(radius: phase.isIdentity ? 0 : 2)
                            }
                            .id(index)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.viewAligned)
            .scrollPosition(id: $selectedImageIndex)
            .contentMargins(.horizontal, 16, for: .scrollContent)
            
            if images.count > 1 {
                HStack(spacing: 6) {
                    ForEach(0..<images.count, id: \.self) { index in
                        Circle()
                            .fill(index == (selectedImageIndex ?? 0)
                                  ? Color(red: 0.72, green: 0.41, blue: 0.25)
                                  : Color.secondary.opacity(0.35))
                            .frame(width: 6, height: 6)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
    
    private func detailBadge(title: String, value: String, systemImage: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Label(value, systemImage: systemImage)
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
    }

    private func startNavigation() {
        guard let userCoordinate = locationManager.userLocation else {
            showLocationAlert = true
            return
        }

        let destination = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
        let cityId = OfflineCityDataStore.shared.getCityId(for: destination)
        print("Fielmedina Debug: destination = \(destination.latitude), \(destination.longitude)")
        print("Fielmedina Debug: resolved cityId = \(cityId)")
        print("Fielmedina Debug: downloadedCityIds = \(OfflineCityDataStore.shared.downloadedCityIds)")
        print("Fielmedina Debug: cachedCities = \(OfflineCityDataStore.shared.cachedCities)")
        if !OfflineCityDataStore.shared.hasCityData(cityId: cityId) {
            missingCityName = OfflineCityDataStore.shared.getCityName(for: cityId)
            showDownloadRequiredAlert = true
            return
        }

        isNavigationLoading = true
        isNavigationPresented = true

        let origin = CLLocationCoordinate2D(latitude: userCoordinate.latitude, longitude: userCoordinate.longitude)
        let options = NavigationRouteOptions(coordinates: [origin, destination])
        options.profileIdentifier = .walking

        Task {
            do {
                let routingProvider = await MainActor.run { MapboxNavigationProviderStore.routingProvider() }
                let response = try await routingProvider.calculateRoutes(options: options).value
                
                await MainActor.run {
                    navigationRoutes = response
                    // isNavigationLoading will be set to false by NavigationCoverView when Mapbox is ready
                }
            } catch {
                await MainActor.run {
                    navigationErrorMessage = error.localizedDescription
                    showNavigationErrorAlert = true
                    isNavigationLoading = false
                    isNavigationPresented = false // Dismiss loader on error
                }
            }
        }
    }
    
}

private struct NavigationCoverView: View {
    @Binding var routes: NavigationRoutes?
    let provider: MapboxNavigationProvider
    let locationName: String
    let userLocation: CLLocationCoordinate2D?
    @Binding var isLoading: Bool
    let onDismiss: () -> Void
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            if let routes = routes {
                MapboxNavigationView(
                    navigationRoutes: routes,
                    mapboxNavigationProvider: provider,
                    userLocation: userLocation,
                    onReady: {
                        withAnimation(.easeOut(duration: 0.3)) {
                            isLoading = false
                        }
                    },
                    onDismiss: onDismiss
                )
                .ignoresSafeArea()
            } else {
                Color(red: 0.72, green: 0.41, blue: 0.25)
                    .ignoresSafeArea()
            }
            
            if isLoading || routes == nil {
                ZStack {
                    Color(red: 0.72, green: 0.41, blue: 0.25)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 24) {
                        ZStack {
                            Circle()
                                .stroke(Color.white.opacity(0.2), lineWidth: 4)
                                .frame(width: 58, height: 58)
                            
                            Circle()
                                .trim(from: 0, to: 0.7)
                                .stroke(Color.white, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                                .frame(width: 58, height: 58)
                                .rotationEffect(.degrees(isAnimating ? 360 : 0))
                                .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: isAnimating)
                        }
                        .onAppear {
                            isAnimating = true
                        }
                        
                        VStack(spacing: 8) {
                            Text("Preparing navigation to")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(.white.opacity(0.8))
                            
                            Text(locationName)
                                .font(.system(size: 24, weight: .bold))
                                .foregroundStyle(.white)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                        }
                    }
                }
                .transition(.opacity)
            }
        }
        .onAppear {
             // Navigation cover appeared
        }
        .onChange(of: routes != nil) {
             // Routes changed, view will update automatically
        }
    }
}

#Preview {
    LocationDetailView(location: Location.sampleLocations[0])
}
