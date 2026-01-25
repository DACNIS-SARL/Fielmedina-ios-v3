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
    
    @State private var navigationRoutes: NavigationRoutes?
    @State private var isCalculatingRoute = false
    @State private var routeError: String?
    @State private var showNavigation = false
    
    // Resume functionality state
    @State private var completedWaypoints: Set<Int> = []
    @State private var currentWaypointIndex: Int = 0
    @State private var hasStartedNavigation = false
    @State private var navigationStartTime: Date?
    
    // Bottom sheet for marker details
    @State private var selectedWaypoint: TrailWaypoint?
    @State private var locationManager = LocationManager()
    
    @Environment(\.dismiss) private var dismiss
    
    private var canResume: Bool {
        return hasStartedNavigation && !completedWaypoints.isEmpty
    }
    
    var body: some View {
        ZStack {
            if showNavigation, let routes = navigationRoutes {
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
                    }
                )
                .ignoresSafeArea()
            } else {
                loadingView
            }
        }
        .background(Color.black)
        .onAppear {
            locationManager.requestPermission()
            locationManager.startUpdatingLocation()
            startNavigationFromCurrentWaypoint()
        }
        .onDisappear {
            locationManager.stopUpdatingLocation()
        }
        .sheet(item: Binding(
            get: { selectedWaypoint.map { WaypointWrapper(waypoint: $0) } },
            set: { selectedWaypoint = $0?.waypoint }
        )) { wrapper in
            HikingLocationSheet(waypoint: wrapper.waypoint)
                .presentationDetents([.medium, .large])
        }
    }
    
    // Wrapper for sheet identifiable
    struct WaypointWrapper: Identifiable {
        let id = UUID()
        let waypoint: TrailWaypoint
    }
    
    private var loadingView: some View {
        ZStack {
            Color(red: 0.72, green: 0.41, blue: 0.25)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(.white)
                    .scaleEffect(x: 1.5, y: 1.5, anchor: .center)
                
                Text("Preparing hiking navigation to")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.8))
                
                Text(hikingRoute.displayName)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
        }
    }
    
    // MARK: - Logic
    
    private func startNavigationFromCurrentWaypoint() {
        loadNavigationProgress()
        
        if canResume {
            // For simplicity, we can just ask or start fresh?
            // User code showed an alert. For this "modern" version, let's just resume if possible, or maybe just start fresh for MVP stability.
            // Let's implement auto-resume logic or start fresh if finished.
            if completedWaypoints.count == hikingRoute.waypoints.count {
                startFreshNavigation()
            } else {
                // Determine start index.
                // If we are resuming, we should ideally start from the last user location or the last completed waypoint.
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
    
    private func calculateHikingRoute() {
        isCalculatingRoute = true
        
        Task {
            // Simulate waiting for location
            // In real app we need LocationManager to give us current location
            guard let userLocation = locationManager.userLocation else {
                  // Handle error
                  return
            }
            
            let provider = MapboxNavigationProviderStore.shared
            let routingProvider = provider.routingProvider()
            
            var waypoints: [Waypoint] = []
            
            // Start: User Location
            waypoints.append(Waypoint(coordinate: userLocation, name: "Start"))
            
            // Add hiking waypoints
            // Logic: if resuming, maybe skip already visited ones?
            // Users usually want to see the whole route, but navigate to the next point.
            // If we skip, the route shape changes.
            // Better to include all, but maybe silently pass visited ones?
            // Mapbox supports "silent waypoints" or just treat them as standard.
            
            for waypoint in hikingRoute.waypoints {
                let wp = Waypoint(coordinate: CLLocationCoordinate2D(latitude: waypoint.latitude, longitude: waypoint.longitude), name: waypoint.name)
                waypoints.append(wp)
            }
            
            let options = NavigationRouteOptions(waypoints: waypoints)
            options.profileIdentifier = .walking
            
            do {
                let response = try await routingProvider.calculateRoutes(options: options).value
                await MainActor.run {
                    self.navigationRoutes = response
                    self.showNavigation = true
                    self.isCalculatingRoute = false
                }
            } catch {
                print("Error calculating route: \(error)")
                await MainActor.run {
                    isCalculatingRoute = false
                    // Show error
                }
            }
        }
    }
}
