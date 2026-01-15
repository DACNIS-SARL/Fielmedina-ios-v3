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
        guard let userInfo = userInfo,
              let screen = userInfo["screen"] as? String else { return }
        
        switch screen.lowercased() {
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
