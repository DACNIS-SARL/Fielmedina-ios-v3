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
    
    var body: some View {
        TabView(selection: $selectedTab){
            HomeView().tabItem{Image(systemName: selectedTab == 0 ? "house.fill" : "house")
                Text("home_button")
            }.tag(0)
            
            MapView()
                .tabItem {
                    Image(systemName: selectedTab == 1 ? "safari" : "safari.fill")
                    Text("map_button")
                }
                .tag(1)
            
            HikingView()
                .tabItem {
                    Image(systemName: selectedTab == 2 ? "figure.hiking" : "figure.hiking")
                    Text("hiking_button")
                }
                .tag(2)
            
            
            
            UtilView()
                .tabItem {
                    Image(systemName: selectedTab == 3 ? "phone.badge.waveform" : "phone.badge.waveform.fill")
                    Text("util_button")
                }
                .tag(3)
        }
        .onAppear {
            deepLinkCancellable = NotificationCenter.default
                .publisher(for: .pushDeepLink)
                .sink { notification in
                    guard let userInfo = notification.userInfo else { return }
                    let screen = (userInfo["screen"] as? String) ?? ""
                    
                    switch screen.lowercased() {
                    case "home":
                        selectedTab = 0
                    case "map", "maps":
                        selectedTab = 1
                    case "hiking", "trails":
                        selectedTab = 2
                    case "util", "utils", "settings":
                        selectedTab = 3
                    default:
                        break
                    }
                }
        }
        .onDisappear {
            deepLinkCancellable?.cancel()
            deepLinkCancellable = nil
        }
    }
}

#Preview {
    MainNavigationView()
}

