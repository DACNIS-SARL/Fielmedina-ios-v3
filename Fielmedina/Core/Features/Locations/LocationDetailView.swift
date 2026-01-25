//
//  LocationDetailView.swift
//  Fielmedina
//
//  Created by Aslan on 1/23/26.
//

import SwiftUI
import AVFoundation
import NaturalLanguage
import CoreLocation
import MapboxNavigationCore

struct LocationDetailView: View {
    let location: Location
    
    @State private var selectedImageIndex = 0
    @State private var speechManager = LocationSpeechManager()
    @State private var locationManager = LocationManager()
    private let mapboxNavigationProvider = MapboxNavigationProviderStore.shared
    @State private var navigationRoutes: NavigationRoutes?
    @State private var isNavigationPresented = false
    @State private var isNavigationLoading = false
    @State private var showLocationAlert = false
    @State private var showNavigationErrorAlert = false
    @State private var navigationErrorMessage = ""
    
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
        .task {
            locationManager.requestPermission()
            locationManager.startUpdatingLocation()
        }
        .onDisappear {
            locationManager.stopUpdatingLocation()
        }
        .fullScreenCover(isPresented: $isNavigationPresented) {
            if let navigationRoutes {
                ZStack {
                    MapboxNavigationView(
                        navigationRoutes: navigationRoutes,
                        mapboxNavigationProvider: mapboxNavigationProvider,
                        onReady: {
                            isNavigationLoading = false
                        },
                        onDismiss: {
                            self.navigationRoutes = nil
                            isNavigationPresented = false
                            isNavigationLoading = false
                        }
                    )
                    .ignoresSafeArea()

                    if isNavigationLoading {
                        Color.black.opacity(0.6)
                            .ignoresSafeArea()
                        ProgressView("Loading navigation...")
                            .foregroundStyle(.white)
                            .padding(16)
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                }
            }
        }
        .alert("Location Access Required", isPresented: $showLocationAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
        } message: {
            Text("To start navigation, please enable location access in Settings. Tap 'Location' and select 'While Using the App'.")
        }
        .alert("Navigation Error", isPresented: $showNavigationErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(navigationErrorMessage)
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
                    startNavigation()
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
                if let schedule = location.displaySchedule {
                    detailBadge(title: "Opening Hours", value: schedule, systemImage: "clock")
                }
                if let admission = location.displayAdmission {
                    detailBadge(title: "Admission Fee", value: "\(admission) TND", systemImage: "dollarsign.circle")
                }
                Spacer(minLength: 0)
                
            }
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
            .frame(maxWidth: .infinity, alignment: .trailing)
            
            if let story = location.displayStory {
                Text(story.htmlToMarkdown())
                    .font(.body)
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

    private func startNavigation() {
        guard let userCoordinate = locationManager.userLocation else {
            showLocationAlert = true
            return
        }

        let origin = CLLocationCoordinate2D(latitude: userCoordinate.latitude, longitude: userCoordinate.longitude)
        let destination = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
        let options = NavigationRouteOptions(coordinates: [origin, destination])
        let request = mapboxNavigationProvider.routingProvider().calculateRoutes(options: options)

        Task {
            switch await request.result {
            case .failure(let error):
                await MainActor.run {
                    navigationErrorMessage = error.localizedDescription
                    showNavigationErrorAlert = true
                    isNavigationLoading = false
                }
            case .success(let routes):
                await MainActor.run {
                    navigationRoutes = routes
                    isNavigationLoading = true
                    isNavigationPresented = true
                }
            }
        }
    }
    
}

final class LocationSpeechManager {
    private let synthesizer = AVSpeechSynthesizer()
    
    func speak(text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        
        configureAudioSession()
        
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(trimmed)
        let detectedLang = recognizer.dominantLanguage?.rawValue ?? "en"
        let normalizedLang = normalizedLanguage(from: detectedLang)
        
        let selectedVoice = preferredVoice(for: normalizedLang) ?? AVSpeechSynthesisVoice(language: normalizedLang)
        let spokenText = sanitizedText(trimmed, language: normalizedLang, voice: selectedVoice)
        let utterance = AVSpeechUtterance(string: spokenText)
        utterance.voice = selectedVoice
        utterance.rate = 0.48
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0
        
        synthesizer.speak(utterance)
    }
    
    private func configureAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
            try session.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Speech audio session error: \(error.localizedDescription)")
        }
    }
    
    private func preferredVoice(for language: String) -> AVSpeechSynthesisVoice? {
        let prefix = String(language.prefix(2))
        let candidates = AVSpeechSynthesisVoice.speechVoices().filter { $0.language.hasPrefix(prefix) }
        for quality in [AVSpeechSynthesisVoiceQuality.premium, .enhanced, .default] {
            if let voice = candidates.first(where: { $0.quality == quality }) {
                return voice
            }
        }
        return candidates.first
    }
    
    private func normalizedLanguage(from detected: String) -> String {
        let prefix = String(detected.prefix(2))
        switch prefix {
        case "fr":
            return "fr-FR"
        case "en":
            return "en-US"
        default:
            return detected
        }
    }
    
    private func sanitizedText(_ text: String, language: String, voice: AVSpeechSynthesisVoice?) -> String {
        let prefix = String(language.prefix(2))
        guard prefix == "fr", voice?.quality == .default else {
            return text
        }
        let folded = text.folding(options: [.diacriticInsensitive, .widthInsensitive], locale: Locale(identifier: "fr"))
        return folded
            .replacingOccurrences(of: "œ", with: "oe")
            .replacingOccurrences(of: "Œ", with: "OE")
    }
    
    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
    }
}

#Preview {
    LocationDetailView(location: Location.sampleLocations[0])
}
