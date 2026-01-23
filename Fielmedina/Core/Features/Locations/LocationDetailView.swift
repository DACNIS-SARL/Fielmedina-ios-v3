//
//  LocationDetailView.swift
//  Fielmedina
//
//  Created by Aslan on 1/23/26.
//

import SwiftUI
import AVFoundation

struct LocationDetailView: View {
    let location: Location
    
    @State private var selectedImageIndex = 0
    @State private var speechManager = LocationSpeechManager()
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(alignment: .leading, spacing: 0) {
                HeroBanner(imageURL: location.imageURL, showText: false)
                    .frame(maxWidth: .infinity)
                
                detailsCard
            }
            .frame(maxWidth: .infinity)
        }
        .coordinateSpace(name: "scroll")
        .ignoresSafeArea(edges: .top)
        .ignoresSafeArea(edges: .horizontal)
        .navigationTitle(location.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                SettingsButton()
            }
        }
    }
    
    private var detailsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(location.displayName)
                .font(.title3)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
            
            HStack(spacing: 12) {
                Button {
                    FirebaseUtils.trackButtonTap(buttonName: "start_navigation", screenName: "LocationDetail")
                } label: {
                    Label("Start Navigation", systemImage: "location.north.line")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color(red: 0.72, green: 0.41, blue: 0.25))
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                
                Button {
                    FirebaseUtils.trackButtonTap(buttonName: "open_ar", screenName: "LocationDetail")
                } label: {
                    Image(systemName: "cube.transparent")
                        .font(.system(size: 22, weight: .semibold))
                        .frame(width: 52, height: 52)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 50, style: .continuous))
                }
                .buttonStyle(.plain)
            }
            
            imageCarousel
            
            AdsCarousel()
            
            if let category = location.category?.displayName {
                Text(category.uppercased())
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(red: 0.72, green: 0.41, blue: 0.25))
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
            }
            
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 12) {
                    if let schedule = location.displaySchedule {
                        detailBadge(title: "Opening Hours", value: schedule, systemImage: "clock")
                    }
                    if let admission = location.displayAdmission {
                        detailBadge(title: "Admission Fee", value: "\(admission) TND", systemImage: "dollarsign.circle")
                    }
                }
                
                Spacer(minLength: 0)
                
                Button {
                    if let story = location.displayStory {
                        speechManager.speak(text: story)
                    }
                } label: {
                    Image(systemName: "waveform")
                        .font(.system(size: 22, weight: .semibold))
                        .frame(width: 56, height: 56)
                        .background(Color(red: 0.72, green: 0.41, blue: 0.25))
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 50, style: .continuous))
                }
                .buttonStyle(.plain)
            }
            
            if let story = location.displayStory {
                Text(story.htmlToMarkdown())
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .padding(.horizontal, 0)
        .padding(.top, -24)
        .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 6)
    }
    private var imageCarousel: some View {
        let images = location.images ?? []
        
        return ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 12) {
                ForEach(Array(images.enumerated()), id: \.offset) { index, image in
                    FielmedinaImage(url: image.displayURL, contentMode: .fill)
                        .containerRelativeFrame(.horizontal)
                        .aspectRatio(16/9, contentMode: .fill)
                        .frame(maxHeight: 450)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .scrollTransition(.animated, axis: .horizontal) { content, phase in
                            content
                                .scaleEffect(phase.isIdentity ? 1 : 0.9)
                                .blur(radius: phase.isIdentity ? 0 : 2)
                        }
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.viewAligned)
        .contentMargins(.horizontal, 16, for: .scrollContent)
    }
    
    private func detailBadge(title: String, value: String, systemImage: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Label(value, systemImage: systemImage)
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
    }
    
}

final class LocationSpeechManager {
    private let synthesizer = AVSpeechSynthesizer()
    
    func speak(text: String) {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = 0.5
        utterance.voice = AVSpeechSynthesisVoice(language: Locale.current.language.languageCode?.identifier ?? "en")
        synthesizer.speak(utterance)
    }
}

#Preview {
    LocationDetailView(location: Location.sampleLocations[0])
}
