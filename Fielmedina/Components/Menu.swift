//
//  Menu.swift
//  Fielmedina
//
//  Created by Aslan on 1/7/26.
//

import SwiftUI
import Combine

/// Deep link destinations handled at the root navigation level
enum DeepLinkDestination: Hashable {
    case eventDetail(id: String)
    case locationDetail(id: String)
}

struct MainNavigationView: View {
    @State private var selectedTab = 0
    @State private var deepLinkCancellable: AnyCancellable?
    @State private var deepLinkPath = NavigationPath()
    
    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground()
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
    
    var body: some View {
        NavigationStack(path: $deepLinkPath) {
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
            .navigationDestination(for: DeepLinkDestination.self) { destination in
                switch destination {
                case .eventDetail(let id):
                    DeepLinkEventDetailView(eventId: id)
                case .locationDetail(let id):
                    DeepLinkLocationDetailView(locationId: id)
                }
            }
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
        
        // Clear any existing deep link navigation first
        deepLinkPath = NavigationPath()
        
        switch screen.lowercased() {
        case "event_detail":
            if let eventId = payload["event_id"] as? String {
                selectedTab = 0
                FirebaseUtils.trackScreenView(screenName: "event_detail", screenClass: "DeepLink_Notification")
                // Navigate directly — no delay, no NotificationCenter hack
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    deepLinkPath.append(DeepLinkDestination.eventDetail(id: eventId))
                }
            }
        case "location_detail":
            if let locationId = payload["location_id"] as? String {
                selectedTab = 0
                FirebaseUtils.trackScreenView(screenName: "location_detail", screenClass: "DeepLink_Notification")
                // Navigate directly — no delay, no NotificationCenter hack
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    deepLinkPath.append(DeepLinkDestination.locationDetail(id: locationId))
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
