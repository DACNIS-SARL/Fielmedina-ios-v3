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
    let events: [Event]
    let showShowAllButton: Bool
    
    init(
        title: LocalizedStringKey,
        subtitle: LocalizedStringKey? = nil,
        events: [Event],
        showShowAllButton: Bool = true
    ) {
        self.title = title
        self.subtitle = subtitle
        self.events = events
        self.showShowAllButton = showShowAllButton
    }
    
    var displayedEvents: [Event] {
        Array(events.prefix(5))
    }
    
    var body: some View {
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
                
                if showShowAllButton {
                    NavigationLink("Show All") {
                        AllEventsListView()
                    }
                    .buttonStyle(CustomButtonStyle())
                    .sensoryFeedback(.impact(weight: .light), trigger: true)
                }
            }
            .padding(.horizontal)
            
            if displayedEvents.isEmpty {
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
                    subtitle: "Don't miss these experiences",
                    events: EventsData.sampleEvents
                )
                CarouselListEvent(
                    title: "Featured Events",
                    events: EventsData.sampleEvents,
                    showShowAllButton: false
                )
            }
        }
    }
}
