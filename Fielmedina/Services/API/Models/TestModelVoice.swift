//
//  TestModelVoice.swift
//  Fielmedina
//
//  Created by Aslan on 1/13/26.
//

import SwiftUI
import AVFoundation
import NaturalLanguage
import Observation

@Observable
class TestSpeechManager {
    private var synthesizer = AVSpeechSynthesizer()
    
    func speak(text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }

        configureAudioSession()
        
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)
        let detectedLang = recognizer.dominantLanguage?.rawValue ?? "en-US"
        
        let utterance = AVSpeechUtterance(string: trimmed)
        let preferredVoice = AVSpeechSynthesisVoice.speechVoices().first { voice in
            voice.language.contains(detectedLang) &&
            (voice.quality == .enhanced || voice.quality == .premium)
        }
        
        utterance.voice = preferredVoice ?? AVSpeechSynthesisVoice(language: detectedLang)
        
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
    
    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
    }
}

// MARK: - Standalone View
struct TestModelVoiceView: View {
    @State private var speechManager = TestSpeechManager()
    @State private var textInput: String = "À l’entrée de la médina de Monastir, le mausolée de Bourguiba s’élève comme un lieu de mémoire plus que de pouvoir. Construit en pierre ocre et couronné de coupoles dorées, il rend hommage à Habib Bourguiba, père de la Tunisie moderne. L’allée solennelle qui mène au tombeau invite au recueillement, où l’architecture s’exprime par la symétrie, la lumière et le silence. Plus qu’un monument, le mausolée conserve une page essentielle de l’identité nationale, mêlant histoire contemporaine et héritage architectural islamique."
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Voice Tester")
                .font(.headline)
            
            TextEditor(text: $textInput)
                .frame(height: 120)
                .padding(8)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemGray6)))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.gray.opacity(0.2)))
            
            HStack(spacing: 20) {
                Button {
                    speechManager.speak(text: textInput)
                } label: {
                    Label("Read Aloud", systemImage: "speaker.wave.2.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
               
                Button {
                    speechManager.stop()
                } label: {
                    Image(systemName: "stop.fill")
                        .foregroundColor(.white)
                }
                .padding()
                .background(Color.red)
                .clipShape(Circle())
            }
        }
        .padding()
    }
}

#Preview {
    TestModelVoiceView()
}
