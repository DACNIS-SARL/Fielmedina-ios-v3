//
//  HomeView.swift
//  Fielmedina
//
//  Created by Aslan on 1/7/26.
//

import SwiftUI

struct HomeView: View {
    let events = EventsData.sampleEvents
    @State private var showTaxiButton = false

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                Color(.systemBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 0) {
                        HeroBanner(showTaxiButton: showTaxiButton)
                            .zIndex(10)
                        
                        VStack(spacing: 32) {
                            CarouselListEvent(
                                title: "Top Attractions",
                                subtitle: "Top places for you",
                                events: events
                            )
                            .padding(.top, 80)
                            
                            CarouselListEvent(
                                title: "Best Experiences",
                                subtitle: "Top events",
                                events: events
                            )
                            .padding(.top, 50)
                            
                            // More sections...
                        }
                        .background(Color(.systemBackground))
                        .zIndex(0)
                        .padding(.bottom, 100)
                    }
                }
                .ignoresSafeArea()
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    SettingsButton()
                }
            }
        }
    }
}

#Preview {
    HomeView()
}
