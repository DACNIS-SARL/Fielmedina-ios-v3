//
//  HikingLocationSheet.swift
//  Fielmedina
//
//  Created by Aslan on 1/25/26.
//

import SwiftUI
import AVFoundation
import NaturalLanguage

struct HikingLocationSheet: View {
    let waypoint: TrailWaypoint
    
    @State private var speechManager = LocationSpeechManager()
    
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
                        if let storyText {
                            speechManager.speak(text: storyText)
                        }
                    } label: {
                        Image(systemName: "waveform")
                            .font(.system(size: 22, weight: .semibold))
                            .frame(width: 52, height: 52)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 50, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    
                    Button {
                        FirebaseUtils.trackButtonTap(buttonName: "open_ar", screenName: "HikingWaypoint")
                    } label: {
                        Image(systemName: "cube.transparent")
                            .font(.system(size: 22, weight: .semibold))
                            .frame(width: 52, height: 52)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 50, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    
                    Spacer(minLength: 0)
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
    }
}

#Preview {
    HikingLocationSheet(waypoint: TrailWaypoint(
        order: 0,
        name: "Sample Location",
        latitude: 35.0,
        longitude: 10.0,
        images: Location.sampleLocations[0].images,
        storyEn: Location.sampleLocations[0].storyEn,
        storyFr: Location.sampleLocations[0].storyFr
    ))
}
