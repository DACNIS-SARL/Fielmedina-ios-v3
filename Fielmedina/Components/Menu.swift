//
//  Menu.swift
//  Fielmedina
//
//  Created by Aslan on 1/7/26.
//

import SwiftUI
import Combine

// MARK: - Deep Link Destination

/// Each notification tap creates a fresh UUID so SwiftUI always presents the cover.
struct DeepLinkDestination: Identifiable {
    let id = UUID()
    let entityId: String
    
    enum Kind { case event, location, allTips }
    let kind: Kind
}

// MARK: - Main Navigation

struct MainNavigationView: View {
    @State private var selectedTab = 0
    @State private var deepLinkCancellable: AnyCancellable?
    @State private var deepLinkDestination: DeepLinkDestination?
    
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
        .fullScreenCover(item: $deepLinkDestination) { destination in
            NavigationStack {
                Group {
                    switch destination.kind {
                    case .event:
                        DeepLinkEventDetailView(eventId: destination.entityId)
                    case .location:
                        DeepLinkLocationDetailView(locationId: destination.entityId)
                    case .allTips:
                        AllTipsListView()
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            deepLinkDestination = nil
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
                // Dismiss any existing cover first, then present the new one
                deepLinkDestination = nil
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    deepLinkDestination = DeepLinkDestination(entityId: eventId, kind: .event)
                }
            }
        case "location_detail":
            if let locationId = payload["location_id"] as? String {
                FirebaseUtils.trackScreenView(screenName: "location_detail", screenClass: "DeepLink_Notification")
                deepLinkDestination = nil
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    deepLinkDestination = DeepLinkDestination(entityId: locationId, kind: .location)
                }
            }
        case "tips", "all_tips", "alltips":
            FirebaseUtils.trackScreenView(screenName: "all_tips", screenClass: "DeepLink_Notification")
            deepLinkDestination = nil
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                deepLinkDestination = DeepLinkDestination(entityId: "", kind: .allTips)
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

#Preview {
    MainNavigationView()
}
