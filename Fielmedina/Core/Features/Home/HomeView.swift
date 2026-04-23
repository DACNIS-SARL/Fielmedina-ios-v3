//
//  HomeView.swift
//  Fielmedina
//
//  Created by Aslan on 1/15/26.
//


import SwiftUI

enum HomeNavigationDestination: Hashable {
    case allLocations
    case allEvents
    case allTips
    case publicTransports
    case taxiBooking
    case eventDetail(Event)
    case locationDetail(Location)
}

struct HomeView: View {
    @State private var showTaxiButton = false
    @State private var scrollOffset: CGFloat = 0
    @State private var navigationPath = NavigationPath()
    @State private var refreshTrigger = 0

    
    private let buttonStickyThreshold: CGFloat = 180
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            ScrollView(showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: 0, pinnedViews: []) {
                    HeroBanner()
                        .frame(maxWidth: .infinity)
                    
                    VStack(spacing: 0) {
                        actionButtons
                            .padding(.horizontal, 16)
                            .padding(.top, -34)
                            .zIndex(1)
                            .opacity(areButtonsSticky ? 0 : 1)
                            .allowsHitTesting(!areButtonsSticky)
                    }
                    .frame(height: 56)
                    
                    // Main Content
                    VStack(spacing: 32) {
                        CarouselListLocations(
                            title: "Top Attractions",
                            subtitle: "Top places for you",
                            refreshTrigger: $refreshTrigger
                        )
                        .padding(.top, 24)
                        
                        AdsCarousel(refreshTrigger: $refreshTrigger)
                        
                        CarouselListEvent(
                            title: "Best Experiences",
                            subtitle: "Top events",
                            refreshTrigger: $refreshTrigger
                        )
                        .padding(.top, 16)
                        
                        TipsCarousel()
                            .padding(.top, 16)
                    }
                    .background(Color(.systemBackground))
                    .padding(.bottom, 100)
                }
                .frame(maxWidth: .infinity)
            }
            .refreshable {
                refreshTrigger += 1
                // We add a small delay to allow child views to start their tasks
                try? await Task.sleep(nanoseconds: 1_000_000_000)
            }
            .coordinateSpace(name: "scroll")
            .onScrollGeometryChange(for: CGFloat.self) { geo in
                geo.contentOffset.y + geo.contentInsets.top
            } action: { _, newValue in
                scrollOffset = newValue
            }
            .background(Color(.systemBackground))
            .ignoresSafeArea(.keyboard)
            .ignoresSafeArea(edges: .top)
            .ignoresSafeArea(edges: .horizontal)
            .animation(.smooth(duration: 0.3), value: areButtonsSticky)
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    HStack(spacing: 8) {
                        if areButtonsSticky {
                            publicTransportIcon
                                .transition(.move(edge: .trailing).combined(with: .opacity))
                            if showTaxiButton {
                                taxiBookingIcon
                                    .transition(.move(edge: .trailing).combined(with: .opacity))
                            }
                        }
                        SettingsButton()
                    }
                    .animation(.smooth(duration: 0.3), value: areButtonsSticky)
                }
            }
            .toolbarBackground(areButtonsSticky ? .visible : .hidden, for: .navigationBar)
            .navigationDestination(for: HomeNavigationDestination.self) { destination in
                switch destination {
                case .allLocations:
                    AllLocationListView()
                case .allEvents:
                    AllEventsListView()
                case .allTips:
                    AllTipsListView()
                case .publicTransports:
                    PublicTransports()
                case .taxiBooking:
                    TaxiBooking()
                case .eventDetail(let event):
                    EventDetailView(event: event)
                case .locationDetail(let location):
                    LocationDetailView(location: location)
                }
            }

        }
    }
    
    private var areButtonsSticky: Bool {
        scrollOffset > buttonStickyThreshold
    }
    
    private var actionButtons: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 12) {
                publicTransportButton
                if showTaxiButton {
                    taxiBookingButton
                }
            }
            
            HStack(spacing: 8) {
                publicTransportButton.scaleEffect(CGFloat(0.9), anchor: .center)
                if showTaxiButton {
                    taxiBookingButton.scaleEffect(CGFloat(0.9), anchor: .center)
                }
            }
            
            VStack(spacing: 8) {
                publicTransportButton
                if showTaxiButton {
                    taxiBookingButton
                }
            }
        }
    }
    
    private var publicTransportButton: some View {
        NavigationLink(value: HomeNavigationDestination.publicTransports) {
            HStack(spacing: 8) {
                Image(systemName: "train.side.rear.car")
                    .font(.system(size: 14, weight: .semibold))
                Text("Public transports")
                    .font(.system(size: 14, weight: .semibold))
                    .lineLimit(1)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .frame(height: 50)
            .background(Color.blue)
            .clipShape(Capsule())
            .shadow(color: .black.opacity(0.1), radius: 4)
        }
        .buttonStyle(.plain)
    }
    
    private var taxiBookingButton: some View {
        NavigationLink(value: HomeNavigationDestination.taxiBooking) {
            HStack(spacing: 8) {
                Image(systemName: "car.fill")
                    .font(.system(size: 14, weight: .semibold))
                Text("Book a Taxi")
                    .font(.system(size: 14, weight: .semibold))
                    .lineLimit(1)
            }
            .foregroundStyle(.black)
            .padding(.horizontal, 16)
            .frame(height: 50)
            .background(Color.yellow)
            .clipShape(Capsule())
            .shadow(color: .black.opacity(0.1), radius: 4)
        }
        .buttonStyle(.plain)
    }
    
    private var publicTransportIcon: some View {
        NavigationLink(value: HomeNavigationDestination.publicTransports) {
            Image(systemName: "train.side.rear.car")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 32, height: 32)
                .background(Color.blue)
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }
    
    private var taxiBookingIcon: some View {
        NavigationLink(value: HomeNavigationDestination.taxiBooking) {
            Image(systemName: "car.fill")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.black)
                .frame(width: 32, height: 32)
                .background(Color.yellow)
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    HomeView()
}
