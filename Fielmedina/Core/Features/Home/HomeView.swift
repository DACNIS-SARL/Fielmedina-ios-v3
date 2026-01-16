//
//  HomeView.swift
//  Fielmedina
//
//  Created by Aslan on 1/7/26.
//

import SwiftUI

struct HomeView: View {
    @State private var viewModel = HomeViewModel()

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                Color(.systemBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 0) {
                        HeroBanner(showTaxiButton: viewModel.showTaxiButton)
                            .zIndex(10)
                        
                        if viewModel.isLoading {
                            ProgressView("Loading events...")
                                .padding(.top, 100)
                        } else if let error = viewModel.errorMessage {
                            VStack(spacing: 12) {
                                Image(systemName: "exclamationmark.triangle")
                                    .font(.title)
                                    .foregroundStyle(.red)
                                Text(error)
                                    .font(.subheadline)
                                    .multilineTextAlignment(.center)
                                Button("Try Again") {
                                    Task { await viewModel.loadData() }
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
                                    events: viewModel.events
                                )
                                .padding(.top, 80)
                                
                                CarouselListEvent(
                                    title: "Best Experiences",
                                    subtitle: "Top events",
                                    events: viewModel.events
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
                await viewModel.loadData()
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
