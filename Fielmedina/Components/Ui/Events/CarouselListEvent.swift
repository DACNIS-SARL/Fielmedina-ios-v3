//
//  CarouselListEvent.swift
//  Fielmedina
//
//  Created by Aslan on 1/9/26.
//

import SwiftUI

struct CarouselListEvent: View {
    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey?
    let showShowAllButton: Bool
    let isBoostedOnly: Bool
    let limit: Int
    let bottomPadding: CGFloat
    
    @State private var events: [Event] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    init(
        title: LocalizedStringKey,
        subtitle: LocalizedStringKey? = nil,
        showShowAllButton: Bool = true,
        isBoostedOnly: Bool = false,
        limit: Int = 5,
        bottomPadding: CGFloat = 0
    ) {
        self.title = title
        self.subtitle = subtitle
        self.showShowAllButton = showShowAllButton
        self.isBoostedOnly = isBoostedOnly
        self.limit = limit
        self.bottomPadding = bottomPadding
    }
    
    var displayedEvents: [Event] {
        Array(events.prefix(limit))
    }
    
    var body: some View {
        Group {
            if isBoostedOnly && !isLoading && events.isEmpty && errorMessage == nil {
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
                            .sensoryFeedback(.impact(weight: .light), trigger: isLoading)
                        }
                    }
                    .padding(.horizontal)
                    
                    if isLoading {
                        HStack(spacing: 16) {
                            ForEach(0..<3, id: \.self) { _ in
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color(.systemGray5))
                                    .frame(width: 320, height: 300)
                            }
                        }
                        .padding(.horizontal)
                        .redacted(reason: .placeholder)
                    } else if let error = errorMessage {
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
                    } else if displayedEvents.isEmpty {
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
                                ForEach(displayedEvents) { event in
                                    EventCardView(event: event)
                                        .onTapGesture {
                                            FirebaseUtils.trackButtonTap(
                                                buttonName: "event_card_\(title)",
                                                screenName: "Home"
                                            )
                                        }
                                }
                            }
                            .padding(.horizontal)
                        }
                        .scrollClipDisabled()
                    }
                }
                .padding(.bottom, bottomPadding)
            }
        }
        .task {
            await loadEvents()
        }
    }
    
    private func loadEvents() async {
        isLoading = true
        errorMessage = nil
        
        do {
            events = try await EventService.shared.fetchEvents(
                limit: Int32(limit),
                boost: isBoostedOnly ? true : nil
            )
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
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
