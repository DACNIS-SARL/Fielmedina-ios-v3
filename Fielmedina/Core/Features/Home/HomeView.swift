//
//  HomeView.swift
//  Fielmedina
//
//  Created by Aslan on 1/7/26.
//

import SwiftUI

enum HomeNavigationDestination: Hashable {
    case allLocations
    case allEvents
    case publicTransports
    case taxiBooking
}

struct HomeView: View {
    @State private var showTaxiButton = true

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                Color(.systemBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 0) {
                        HeroBanner(showTaxiButton: showTaxiButton)
                        
                        VStack(spacing: 32) {
                            CarouselListLocations(
                                title: "Top Attractions",
                                subtitle: "Top places for you"
                            )
                            .padding(.top, 80)
                            
                            CarouselListEvent(
                                title: "Best Experiences",
                                subtitle: "Top events"
                            )
                            .padding(.top, 50)
                            
                            TipsCarousel()
                                .padding(.top, 50)
                        }
                    }
                    .padding(.bottom, 100)
                }
                .ignoresSafeArea()
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    SettingsButton()
                }
            }
            .navigationDestination(for: HomeNavigationDestination.self) { destination in
                switch destination {
                case .allLocations:
                    AllLocationListView()
                case .allEvents:
                    AllEventsListView()
                case .publicTransports:
                    PublicTransports()
                case .taxiBooking:
                    TaxiBooking()
                }
            }
        }
    }
}

#Preview {
    HomeView()
}
