//
//  Menu.swift
//  Fielmedina
//
//  Created by Aslan on 1/7/26.
//

import SwiftUI
import Combine

struct MainNavigationView: View {
    @State private var selectedTab = 0
    @State private var deepLinkCancellable: AnyCancellable?
    
    // Deep link navigation state
    @State private var pendingEventId: String? = nil
    @State private var pendingLocationId: String? = nil
    
    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground()
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("home_button", systemImage: selectedTab == 0 ? "house.fill" : "house")
                }
                .tag(0)
            
            MapView()
                .tabItem {
                    Label("map_button", systemImage: selectedTab == 1 ? "safari.fill" : "safari")
                }
                .tag(1)
            
            HikingView()
                .tabItem {
                    Label("hiking_button", systemImage: "figure.hiking")
                }
                .tag(2)
            
            UtilView()
                .tabItem {
                    Label("util_button", systemImage: selectedTab == 3 ? "phone.badge.waveform.fill" : "phone.badge.waveform")
                }
                .tag(3)
        }
        .onAppear {
            setupDeepLinking()
            OfflineContentPrefetcher.shared.prefetchIfNeeded()
            LocationManager.shared.requestPermission()
            LocationManager.shared.startUpdatingLocation()
        }
        .onDisappear {
            deepLinkCancellable?.cancel()
            deepLinkCancellable = nil
        }
    }
    
    private func setupDeepLinking() {
        deepLinkCancellable = NotificationCenter.default
            .publisher(for: .pushDeepLink)
            .sink { notification in
                handleDeepLink(notification.userInfo)
            }
    }
    
    private func handleDeepLink(_ userInfo: [AnyHashable: Any]?) {
        guard let userInfo = userInfo else { return }
        
        let screen = userInfo["screen"] as? String ?? ""
        let payload = userInfo["payload"] as? [AnyHashable: Any] ?? userInfo
        
        switch screen.lowercased() {
        case "event_detail":
            if let eventId = payload["event_id"] as? String {
                selectedTab = 0
                // Post a notification that HomeView can listen for to navigate to event detail
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    NotificationCenter.default.post(
                        name: .navigateToEventDetail,
                        object: nil,
                        userInfo: ["event_id": eventId]
                    )
                }
            }
        case "location_detail":
            if let locationId = payload["location_id"] as? String {
                selectedTab = 0
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    NotificationCenter.default.post(
                        name: .navigateToLocationDetail,
                        object: nil,
                        userInfo: ["location_id": locationId]
                    )
                }
            }
        case "home":
            // Tips notification → just go to Home tab
            selectedTab = 0
        case "map", "maps":
            selectedTab = 1
        case "hiking", "trails":
            selectedTab = 2
        case "util", "utils":
            selectedTab = 3
        default:
            break
        }
    }
}

extension Notification.Name {
    static let navigateToEventDetail = Notification.Name("navigate_to_event_detail")
    static let navigateToLocationDetail = Notification.Name("navigate_to_location_detail")
}

#Preview {
    MainNavigationView()
}

