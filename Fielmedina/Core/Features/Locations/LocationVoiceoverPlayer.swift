import AVFoundation
import Foundation

@MainActor
@Observable
final class LocationVoiceoverPlayer {
    private var player: AVPlayer?
    private var endObserver: NSObjectProtocol?
    @ObservationIgnored nonisolated(unsafe) private var startTask: Task<Void, Never>?

    private(set) var isPlaying = false

    func toggle(remoteURLString: String) {
        guard let remote = URL(string: remoteURLString) else { return }

        if isPlaying {
            stop()
            return
        }

        let playURL = VoiceoverDiskCache.playbackURL(forRemote: remote)
        isPlaying = true
        startTask = Task { [weak self] in
            await Self.activateAudioSession()
            guard let self, !Task.isCancelled else { return }
            self.startPlayback(url: playURL)
        }
    }

    func stop() {
        startTask?.cancel()
        startTask = nil
        removeEndObserver()
        player?.pause()
        player?.replaceCurrentItem(with: nil)
        player = nil
        isPlaying = false
    }

    private func startPlayback(url: URL) {
        removeEndObserver()
        let item = AVPlayerItem(url: url)
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
    }

    private func removeEndObserver() {
        if let endObserver {
            NotificationCenter.default.removeObserver(endObserver)
        }
        endObserver = nil
    }

    @concurrent
    nonisolated private static func activateAudioSession() async {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
            if #available(iOS 27.0, *) {
                _ = try await session.activate(options: [])
            } else {
                try session.setActive(true, options: .notifyOthersOnDeactivation)
            }
        } catch {
            print("Voiceover audio session error: \(error.localizedDescription)")
        }
    }
}
