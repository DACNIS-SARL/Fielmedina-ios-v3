//
//  VoiceoverDiskCache.swift
//  Fielmedina
//

import CryptoKit
import Foundation

/// Persists remote voiceover AAC files under Caches so `AVPlayer` can play offline after prefetch.
enum VoiceoverDiskCache {
    private static let subdirectory = "Voiceovers"

    private static var directoryURL: URL {
        let base = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let dir = base.appendingPathComponent(subdirectory, isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    private static func fileURL(forRemote remote: URL) -> URL {
        let digest = SHA256.hash(data: Data(remote.absoluteString.utf8))
        let hex = digest.map { String(format: "%02x", $0) }.joined()
        return directoryURL.appendingPathComponent("\(hex).m4a")
    }

    static func cachedFileURL(forRemote remote: URL) -> URL? {
        let local = fileURL(forRemote: remote)
        return FileManager.default.fileExists(atPath: local.path) ? local : nil
    }

    /// Writes the remote file to disk if missing. Safe to call from prefetch or background tasks.
    static func downloadIfNeeded(remote: URL) async throws {
        let destination = fileURL(forRemote: remote)
        guard !FileManager.default.fileExists(atPath: destination.path) else { return }

        var request = URLRequest(url: remote)
        request.cachePolicy = .returnCacheDataElseLoad
        request.timeoutInterval = 45

        let (data, response) = try await URLSession.shared.data(for: request)
        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            throw URLError(.badServerResponse)
        }
        try data.write(to: destination, options: .atomic)
    }

    /// URL to pass to `AVPlayer`: local copy when prefetched, otherwise the remote URL.
    static func playbackURL(forRemote remote: URL) -> URL {
        cachedFileURL(forRemote: remote) ?? remote
    }
}
