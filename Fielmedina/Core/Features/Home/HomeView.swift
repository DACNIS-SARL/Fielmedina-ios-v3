//
//  HomeView.swift
//  Fielmedina
//
//  Created by Aslan on 1/7/26.
//

import SwiftUI

struct HomeView: View {
    @State private var events: [Event] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
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
                        
                        if isLoading {
                            ProgressView("Loading events...")
                                .padding(.top, 100)
                        } else if let error = errorMessage {
                            VStack(spacing: 12) {
                                Image(systemName: "exclamationmark.triangle")
                                    .font(.title)
                                    .foregroundStyle(.red)
                                Text(error)
                                    .font(.subheadline)
                                    .multilineTextAlignment(.center)
                                Button("Try Again") {
                                    Task { await loadEvents() }
                                }
                                .buttonStyle(.bordered)
                            }
                            .padding(.top, 100)
                            .padding(.horizontal)
                        } else {
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
                            }
                            .background(Color(.systemBackground))
                            .zIndex(0)
                        }
                    }
                    .padding(.bottom, 100)
                }
                .ignoresSafeArea()
            }
            .task {
                await loadEvents()
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    SettingsButton()
                }
            }
        }
    }
    
    private func loadEvents() async {
        isLoading = true
        errorMessage = nil
        do {
            events = try await EventService.shared.fetchEvents()
            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }
}

#Preview {
    HomeView()
}
