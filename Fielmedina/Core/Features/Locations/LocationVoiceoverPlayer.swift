//
//  LocationVoiceoverPlayer.swift
//  Fielmedina
//

import AVFoundation
import Foundation

@MainActor
@Observable
final class LocationVoiceoverPlayer {
    private var player: AVPlayer?
    private var endObserver: NSObjectProtocol?

    private(set) var isPlaying = false

    func toggle(remoteURLString: String) {
        guard let remote = URL(string: remoteURLString) else { return }

        if isPlaying {
            stop()
            return
        }

        let playURL = VoiceoverDiskCache.playbackURL(forRemote: remote)
        configureAudioSession()

        removeEndObserver()
        let item = AVPlayerItem(url: playURL)
        let newPlayer = AVPlayer(playerItem: item)
        player = newPlayer

        endObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: item,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.stop()
            }
        }

        newPlayer.play()
        isPlaying = true
    }

    func stop() {
        removeEndObserver()
        player?.pause()
        player?.replaceCurrentItem(with: nil)
        player = nil
        isPlaying = false
    }

    private func removeEndObserver() {
        if let endObserver {
            NotificationCenter.default.removeObserver(endObserver)
        }
        endObserver = nil
    }

    private func configureAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
            try session.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Voiceover audio session error: \(error.localizedDescription)")
        }
    }
}
