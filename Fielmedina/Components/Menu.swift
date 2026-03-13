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
    
    // Deep link state — presented as fullScreenCover
    @State private var deepLinkEventId: String?
    @State private var deepLinkLocationId: String?
    
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
        .fullScreenCover(item: $deepLinkEventId) { eventId in
            NavigationStack {
                DeepLinkEventDetailView(eventId: eventId)
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            Button {
                                deepLinkEventId = nil
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(.primary)
                                    .frame(width: 32, height: 32)
                                    .background(.ultraThinMaterial)
                                    .clipShape(Circle())
                            }
                        }
                    }
            }
        }
        .fullScreenCover(item: $deepLinkLocationId) { locationId in
            NavigationStack {
                DeepLinkLocationDetailView(locationId: locationId)
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            Button {
                                deepLinkLocationId = nil
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(.primary)
                                    .frame(width: 32, height: 32)
                                    .background(.ultraThinMaterial)
                                    .clipShape(Circle())
                            }
                        }
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
        
        switch screen.lowercased() {
        case "event_detail":
            if let eventId = payload["event_id"] as? String {
                FirebaseUtils.trackScreenView(screenName: "event_detail", screenClass: "DeepLink_Notification")
                deepLinkEventId = eventId
            }
        case "location_detail":
            if let locationId = payload["location_id"] as? String {
                FirebaseUtils.trackScreenView(screenName: "location_detail", screenClass: "DeepLink_Notification")
                deepLinkLocationId = locationId
            }
        case "home":
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

// Make String conform to Identifiable for .fullScreenCover(item:)
extension String: @retroactive Identifiable {
    public var id: String { self }
}

#Preview {
    MainNavigationView()
}
