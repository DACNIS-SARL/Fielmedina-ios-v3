//
//  CarouselListEvent.swift
//  Fielmedina
//
//  Created by Aslan on 1/15/26.
//

import SwiftUI

struct CarouselListEvent: View {
    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey?
    let showShowAllButton: Bool
    let isBoostedOnly: Bool
    let limit: Int
    let bottomPadding: CGFloat
    
    @Environment(\.scenePhase) private var scenePhase
    @State private var events: [Event] = []
    @State private var isLoading = true
    @State private var isRefreshing = false
    @State private var isHorizontalRefreshing = false
    @State private var errorMessage: String?
    @Binding var refreshTrigger: Int
    
    init(
        title: LocalizedStringKey,
        subtitle: LocalizedStringKey? = nil,
        showShowAllButton: Bool = true,
        isBoostedOnly: Bool = false,
        limit: Int = 5,
        bottomPadding: CGFloat = 0,
        refreshTrigger: Binding<Int> = .constant(0)
    ) {
        self.title = title
        self.subtitle = subtitle
        self.showShowAllButton = showShowAllButton
        self.isBoostedOnly = isBoostedOnly
        self.limit = limit
        self.bottomPadding = bottomPadding
        self._refreshTrigger = refreshTrigger
    }
    
    var displayedEvents: [Event] {
        Array(events.prefix(limit))
    }
    
    var body: some View {
        if isBoostedOnly && !isLoading && displayedEvents.isEmpty {
            EmptyView()
        } else {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.title2)
                        .bold()
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                if showShowAllButton && !isLoading {
                    NavigationLink(value: HomeNavigationDestination.allEvents) {
                        Text("Show All")
                            .font(.system(size: 16, weight: .semibold))
                            .padding(.horizontal, 18)
                            .padding(.vertical, 12)
                            .background(.ultraThinMaterial)
                            .clipShape(Capsule())
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("show_all_events_button")
                }
            }
            .padding(.horizontal)
            
            if isLoading {
                HStack(spacing: 16) {
                    ForEach(0..<3, id: \.self) { _ in
                        EventCardSkeleton()
                    }
                }
                .padding(.horizontal)
            } else if let error = errorMessage, !isBoostedOnly {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 40))
                        .foregroundStyle(.red)
                    Text(error)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Button("Retry") {
                        Task { await loadEvents() }
                    }
                    .buttonStyle(.bordered)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else if displayedEvents.isEmpty && !isBoostedOnly {
                VStack(spacing: 12) {
                    Image(systemName: "calendar.badge.exclamationmark")
                        .font(.system(size: 40))
                        .foregroundStyle(.secondary)
                    Text("No events available")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        if isHorizontalRefreshing {
                            ProgressView()
                                .padding(.leading, 16)
                                .transition(.scale)
                        }
                        
                        ForEach(displayedEvents) { event in
                            NavigationLink {
                                EventDetailView(event: event)
                            } label: {
                                EventCardView(event: event)
                            }
                            .buttonStyle(.plain)
                            .simultaneousGesture(TapGesture().onEnded {
                                FirebaseUtils.trackButtonTap(
                                    buttonName: "event_card_\(title)",
                                    screenName: "Home"
                                )
                            })
                        }
                    }
                    .padding(.horizontal)
                }
                .onScrollGeometryChange(for: CGFloat.self, of: { geo in
                    return geo.contentOffset.x
                }, action: { oldValue, newValue in
                    let threshold: CGFloat = 100
                    if newValue < -threshold && !isRefreshing && !isHorizontalRefreshing {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        isHorizontalRefreshing = true
                        Task { 
                            await loadEvents(forceRefresh: true) 
                            isHorizontalRefreshing = false
                        }
                    }
                })
                .clipped()
                .transition(.opacity.animation(.easeIn(duration: 0.3)))
            }
        }
        .padding(.bottom, bottomPadding)
        .animation(.easeIn(duration: 0.3), value: isLoading)
        .task {
            await loadEvents()
        }

        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                Task { await loadEvents(forceRefresh: true) }
            }
        }
        .onChange(of: refreshTrigger) { _, _ in
            Task { await loadEvents(forceRefresh: true) }
        }
    }
    }
    private func loadEvents(forceRefresh: Bool = false) async {
        if forceRefresh {
            isRefreshing = true
        } else {
            isLoading = true
        }
        defer { 
            isLoading = false
            isRefreshing = false
        }
        
        do {
            events = try await EventService.shared.fetchEvents(
                limit: Int32(limit),
                boost: isBoostedOnly ? true : nil,
                forceRefresh: forceRefresh
            )
        } catch {
            if !forceRefresh {
                errorMessage = error.localizedDescription
            }
        }
    }
}

#Preview {
    NavigationStack {
        ScrollView {
            VStack(spacing: 32) {
                CarouselListEvent(
                    title: "Upcoming Events",
                    subtitle: "Don't miss these experiences"
                )
                CarouselListEvent(
                    title: "Featured Events",
                    showShowAllButton: false,
                    isBoostedOnly: true
                )
            }
        }
    }
}
