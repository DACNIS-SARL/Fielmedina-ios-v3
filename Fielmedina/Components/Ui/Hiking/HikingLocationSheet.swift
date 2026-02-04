//
//  HikingLocationSheet.swift
//  Fielmedina
//
//  Created by Aslan on 1/25/26.
//

import SwiftUI

struct HikingLocationSheet: View {
    let waypoint: TrailWaypoint
    
    @State private var showARUnavailableAlert = false
    
    private var storyText: String? {
        let isFrench = Locale.current.language.languageCode?.identifier == "fr"
        if isFrench, let story = waypoint.storyFr, !story.isEmpty {
            return story
        }
        return waypoint.storyEn
    }
    
    private var imageURL: String? {
        waypoint.images?.first?.displayURL
    }
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                HeroBanner(imageURL: imageURL, showText: false)
                    .frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                
                Text(waypoint.name)
                    .font(.title3)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                
                HStack(spacing: 12) {
                    Button {
                        FirebaseUtils.trackButtonTap(buttonName: "open_ar", screenName: "HikingWaypoint")
                        showARUnavailableAlert = true
                    } label: {
                        Image(systemName: "cube.transparent")
                            .font(.system(size: 22, weight: .semibold))
                            .frame(width: 52, height: 52)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 50, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    
                    Spacer(minLength: 0)
                    
                    if let category = waypoint.category?.displayName {
                        Text(category.uppercased())
                            .font(.caption)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color(red: 0.72, green: 0.41, blue: 0.25))
                            .foregroundStyle(.white)
                            .clipShape(Capsule())
                    }
                }
                
                AdsCarousel()
                
                if let storyText {
                    Text(storyText.htmlToMarkdown())
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(20)
        }
        .background(Color(.systemBackground))
        .alert(String(localized: "AR not available"), isPresented: $showARUnavailableAlert) {
            Button(String(localized: "OK"), role: .cancel) { }
        } message: {
            Text(String(localized: "This location has no AR experience yet."))
        }
    }
}

#Preview {
    HikingLocationSheet(waypoint: TrailWaypoint(
        order: 0,
        name: "Sample Location",
        latitude: 35.0,
        longitude: 10.0,
        category: Location.sampleLocations[0].category,
        images: Location.sampleLocations[0].images,
        storyEn: Location.sampleLocations[0].storyEn,
        storyFr: Location.sampleLocations[0].storyFr
    ))
}
