//
//  HikingNavigator.swift
//  Fielmedina
//
//  Created by Aslan on 1/25/26.
//

import SwiftUI
import MapboxNavigationCore
import MapboxDirections
import CoreLocation

// MARK: - Navigation Progress Model
struct HikingNavigationProgress: Codable {
    let completedWaypoints: [Int]
    let currentWaypointIndex: Int
    let hasStartedNavigation: Bool
    let navigationStartTime: Date?
}

struct HikingNavigator: View {
    let hikingRoute: Hiking
    let initialUserLocation: CLLocationCoordinate2D?
    
    @State private var navigationRoutes: NavigationRoutes?
    @State private var isCalculatingRoute = false
    @State private var routeError: String?
    @State private var showNavigation = false
    
    // Resume functionality state
    @State private var completedWaypoints: Set<Int> = []
    @State private var currentWaypointIndex: Int = 0
    @State private var hasStartedNavigation = false
    @State private var navigationStartTime: Date?
    
    // State for error handling
    @State private var errorMessage: String?
    @State private var isLocationTimedOut = false
    private let locationTimeout: TimeInterval = 10.0
    
    // UI State
    @State private var selectedWaypoint: TrailWaypoint?
    @State private var isAnimating = false
    @State private var showDownloadRequiredAlert = false
    @State private var missingCityName = ""
    
    @Environment(\.dismiss) private var dismiss
    
    private var canResume: Bool {
        return hasStartedNavigation && !completedWaypoints.isEmpty
    }
    
    var body: some View {
        ZStack {
            if let error = errorMessage {
                errorView(error)
            } else if showNavigation, let routes = navigationRoutes {
                MapboxHikingNavigationView(
                    navigationRoutes: routes,
                    hikingRoute: hikingRoute,
                    completedWaypoints: completedWaypoints,
                    onDismiss: {
                        dismiss()
                    },
                    onWaypointCompleted: { index in
                         markWaypointCompleted(index)
                    },
                    onWaypointTapped: { waypoint in
                        selectedWaypoint = waypoint
                    },
                    onProgressUpdate: { index in
                        updateProgressIndex(index)
                    }
                )
                .ignoresSafeArea()
            } else {
                loadingView
            }
        }
        .background(Color.black)
        .onAppear {
            FirebaseUtils.trackScreenView(screenName: "hiking_navigator_\(hikingRoute.displayName)", screenClass: "HikingNavigator")
            LocationManager.shared.requestPermission()
            LocationManager.shared.startUpdatingLocation()
            startNavigationFromCurrentWaypoint()
        }
        .onDisappear {
            LocationManager.shared.stopUpdatingLocation()
        }
        .sheet(item: $selectedWaypoint) { waypoint in
            HikingLocationSheet(waypoint: waypoint)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .alert(String(localized: "Offline Map Required"), isPresented: $showDownloadRequiredAlert) {
            Button("OK", role: .cancel) { dismiss() }
        } message: {
            Text(String(format: String(localized: "You need to download the offline map for %@ Medina under Settings before starting navigation."), missingCityName))
        }
    }
    
    private var loadingView: some View {
        ZStack {
            Color(red: 0.72, green: 0.41, blue: 0.25)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
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
                            Text(isLocationTimedOut ? "Still waiting for GPS..." : "Preparing hiking navigation to")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(.white.opacity(0.8))
                            
                            Text(hikingRoute.displayName)
                                .font(.system(size: 24, weight: .bold))
                                .foregroundStyle(.white)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                        }
                    }
                
                if isLocationTimedOut {
                    Button("Start anyway") {
                        calculateHikingRoute(force: true)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.white.opacity(0.3))
                    .foregroundStyle(.white)
                    .padding(.top, 10)
                }

                if canResume {
                    Button {
                        startFreshNavigation()
                    } label: {
                        HStack {
                            Image(systemName: "arrow.counterclockwise")
                            Text("Restart from beginning")
                        }
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.white.opacity(0.8))
                    .padding(.top, 5)
                }
            }
        }
    }
    
    private func errorView(_ message: String) -> some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 20) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 50))
                    .foregroundStyle(.orange)
                
                Text("Navigation Error")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                
                Text(message)
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Button("Retry") {
                    errorMessage = nil
                    isLocationTimedOut = false
                    calculateHikingRoute()
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
                
                Button("Go Back") {
                    dismiss()
                }
                .foregroundStyle(.white)
            }
        }
    }
    
    // MARK: - Logic
    
    private func startNavigationFromCurrentWaypoint() {
        let firstCoord = CLLocationCoordinate2D(latitude: hikingRoute.waypoints.first?.latitude ?? 0.0, longitude: hikingRoute.waypoints.first?.longitude ?? 0.0)
        let cityId = OfflineCityDataStore.shared.getCityId(for: firstCoord)
        if !OfflineCityDataStore.shared.hasCityData(cityId: cityId) {
            missingCityName = OfflineCityDataStore.shared.getCityName(for: cityId)
            showDownloadRequiredAlert = true
            return
        }

        loadNavigationProgress()
        
        if canResume {
            if completedWaypoints.count == hikingRoute.waypoints.count {
                startFreshNavigation()
            } else {
                calculateHikingRoute()
            }
        } else {
            startFreshNavigation()
        }
    }
    
    private func startFreshNavigation() {
        completedWaypoints.removeAll()
        currentWaypointIndex = 0
        hasStartedNavigation = true
        calculateHikingRoute()
    }
    
    private func markWaypointCompleted(_ index: Int) {
        completedWaypoints.insert(index)
        currentWaypointIndex = index + 1
        saveNavigationProgress()
    }

    private func updateProgressIndex(_ index: Int) {
        guard index >= 0 else { return }
        currentWaypointIndex = index
        hasStartedNavigation = true
        saveNavigationProgress()
    }
    
    private func saveNavigationProgress() {
        let progress = HikingNavigationProgress(
            completedWaypoints: Array(completedWaypoints),
            currentWaypointIndex: currentWaypointIndex,
            hasStartedNavigation: hasStartedNavigation,
            navigationStartTime: navigationStartTime
        )
        if let data = try? JSONEncoder().encode(progress) {
            UserDefaults.standard.set(data, forKey: "hiking_progress_\(hikingRoute.id)")
        }
    }
    
    private func loadNavigationProgress() {
        if let data = UserDefaults.standard.data(forKey: "hiking_progress_\(hikingRoute.id)"),
           let progress = try? JSONDecoder().decode(HikingNavigationProgress.self, from: data) {
            completedWaypoints = Set(progress.completedWaypoints)
            currentWaypointIndex = progress.currentWaypointIndex
            hasStartedNavigation = progress.hasStartedNavigation
        }
    }
    
    private func calculateHikingRoute(force: Bool = false) {
        isCalculatingRoute = true
        errorMessage = nil
        
        Task {
            // Wait for location if needed
            var attempts = 0
            while LocationManager.shared.userLocation == nil && attempts < 20 && !force {
                try? await Task.sleep(for: .milliseconds(500))
                attempts += 1
                if attempts == 10 {
                    await MainActor.run { isLocationTimedOut = true }
                }
            }
            
            // Use user location or fallback to first waypoint if forced
            // Use provided initial location, user location, or fallback to first waypoint if forced
            let startCoordinate: CLLocationCoordinate2D
            if let initialLoc = initialUserLocation {
                startCoordinate = initialLoc
            } else if let loc = LocationManager.shared.userLocation {
                startCoordinate = loc
            } else if force, let firstWp = hikingRoute.waypoints.first {
                startCoordinate = CLLocationCoordinate2D(latitude: firstWp.latitude, longitude: firstWp.longitude)
            } else {
                await MainActor.run {
                    errorMessage = "Could not determine your location. Please ensure GPS is enabled and you are outside."
                    isCalculatingRoute = false
                }
                return
            }
            
            let routingProvider = await MainActor.run { MapboxNavigationProviderStore.routingProvider() }
            
            var waypoints: [Waypoint] = []
            
            // Start Coordinate
            waypoints.append(Waypoint(coordinate: startCoordinate, name: "Start"))
            
            // Logic: if resuming, we should ideally route to the NEXT uncompleted waypoint
            // and then follow the rest. 
            // If we include completed ones, navigation might try to turn the user around.
            let allPoints = hikingRoute.waypoints
            let remainingPoints = allPoints.enumerated().filter { !completedWaypoints.contains($0.offset) }
            
            if remainingPoints.isEmpty {
                // Should not happen if startNavigationFromCurrentWaypoint logic is correct
                waypoints.append(contentsOf: allPoints.map { 
                    Waypoint(coordinate: CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude), name: $0.name)
                })
            } else {
                // Route to remaining points
                waypoints.append(contentsOf: remainingPoints.map { _, waypoint in
                    Waypoint(coordinate: CLLocationCoordinate2D(latitude: waypoint.latitude, longitude: waypoint.longitude), name: waypoint.name)
                })
            }
            
            let options = NavigationRouteOptions(waypoints: waypoints)
            options.profileIdentifier = .walking
            
            // Mapbox V11+: If we are offline, it should use the OfflineRouter automatically if offline regions are matches
            // but we can also check environment or tiles.
            
            do {
                let response = try await routingProvider.calculateRoutes(options: options).value
                await MainActor.run {
                    self.navigationRoutes = response
                    self.showNavigation = true
                    self.isCalculatingRoute = false
                }
            } catch {
                LogUtils.e("HikingNavigator", "Error calculating route", error)
                await MainActor.run {
                    isCalculatingRoute = false
                    errorMessage = "Navigation failed. If you are offline, please ensure you have downloaded the maps for this area.\n\nError: \(error.localizedDescription)"
                }
            }
        }
    }
}
