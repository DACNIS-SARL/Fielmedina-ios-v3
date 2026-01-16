//
//  CarouselListLocations.swift
//  Fielmedina
//
//  Created by Aslan on 1/16/26.
//

import SwiftUI

struct CarouselListLocations:View {
    let locations: [Location]
    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey?
    let showShowAllButton: Bool
    
    init(
        locations: [Location],
        title: LocalizedStringKey,
        subtitle: LocalizedStringKey? = nil,
        showShowAllButton: Bool = true
    ) {
        self.locations = locations
        self.title = title
        self.subtitle = subtitle
        self.showShowAllButton = showShowAllButton
        
    }
    var displayedLocations: [Location] {
        Array(locations.prefix(10))
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
                        AllLocationListView()
                    }
                    .buttonStyle(CustomButtonStyle())
                    .sensoryFeedback(.impact(weight: .light), trigger: true)
                }
            }
            .padding(.horizontal)
            
            if displayedLocations.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "calendar.badge.exclamationmark")
                        .font(.system(size: 40))
                        .foregroundStyle(.secondary)
                    
                    Text("No locations available")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(displayedLocations) { location in
                            LocationCardView(location: location)
                                .onTapGesture {
                                    FirebaseUtils.trackButtonTap(
                                        buttonName: "location_card_\(title)",
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
                CarouselListLocations(
                    locations: Location.sampleLocations,
                    title: "Top Attractions",
                    subtitle: "Top 10 places for you"
                )
            }
        }
    }
}



extension Location {
    static let sampleLocations: [Location] = [
        Location(
            id: "1",
            nameEn: "Ribat of Sousse",
            nameFr: "Ribat de Sousse",
            latitude: 35.8256,
            longitude: 10.6369,
            category: LocationCategory(
                id: "1",
                nameEn: "Historical Site",
                nameFr: "Site Historique"
            ),
            images: nil,
            openFrom: "09:00",
            openTo: "16:00",
            storyEn: "A historic fortress built in the 8th century",
            storyFr: "Une forteresse historique construite au 8ème siècle",
            admissionFee: "8.00",
            closedDays: nil
        ),
        Location(
            id: "2",
            nameEn: "Great Mosque of Kairouan",
            nameFr: "Grande Mosquée de Kairouan",
            latitude: 35.6781,
            longitude: 10.1042,
            category: LocationCategory(
                id: "2",
                nameEn: "Religious Site",
                nameFr: "Site Religieux"
            ),
            images: nil,
            openFrom: "08:00",
            openTo: "17:30",
            storyEn: "One of the most important mosques in Tunisia",
            storyFr: "L'une des mosquées les plus importantes de Tunisie",
            admissionFee: "0",
            closedDays: nil
        )
    ]
}
