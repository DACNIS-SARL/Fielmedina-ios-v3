//
//  VoiceoverDiskCache.swift
//  Fielmedina
//

import CryptoKit
import Foundation

/// Persists remote voiceover AAC files under Application Support so `AVPlayer` can play
/// offline after prefetch. Application Support is never purged by iOS under storage pressure.
enum VoiceoverDiskCache {
    private static let subdirectory = "Voiceovers"

    /// One-time move of files from the old purgeable Caches/Voiceovers location.
    private static let legacyMigration: Void = {
        let fileManager = FileManager.default
        guard let caches = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first else { return }
        let legacyDir = caches.appendingPathComponent(subdirectory, isDirectory: true)
        guard fileManager.fileExists(atPath: legacyDir.path) else { return }

        let newDir = CacheConfigurator.offlineDataDirectoryURL()
            .appendingPathComponent(subdirectory, isDirectory: true)
        if !fileManager.fileExists(atPath: newDir.path) {
            try? fileManager.createDirectory(at: newDir, withIntermediateDirectories: true)
        }
        if let files = try? fileManager.contentsOfDirectory(at: legacyDir, includingPropertiesForKeys: nil) {
            for file in files {
                try? fileManager.moveItem(at: file, to: newDir.appendingPathComponent(file.lastPathComponent))
            }
        }
        try? fileManager.removeItem(at: legacyDir)
    }()

    private static var directoryURL: URL {
        _ = legacyMigration
        let dir = CacheConfigurator.offlineDataDirectoryURL()
            .appendingPathComponent(subdirectory, isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    private static func fileURL(forRemote remote: URL) -> URL {
        let digest = SHA256.hash(data: Data(remote.absoluteString.utf8))
        let hex = digest.map { String(format: "%02x", $0) }.joined()
        // Use .aac to match the server format and Android implementation
        return directoryURL.appendingPathComponent("\(hex).aac")
    }

    static func cachedFileURL(forRemote remote: URL) -> URL? {
        let local = fileURL(forRemote: remote)
        let exists = FileManager.default.fileExists(atPath: local.path)
        if exists {
            print("🔊 [VoiceoverCache] Local file found: \(local.lastPathComponent)")
        }
        return exists ? local : nil
    }

    /// Writes the remote file to disk if missing. Safe to call from prefetch or background tasks.
    static func downloadIfNeeded(remote: URL) async throws {
        let destination = fileURL(forRemote: remote)
        guard !FileManager.default.fileExists(atPath: destination.path) else { 
            print("🔊 [VoiceoverCache] Already cached: \(destination.lastPathComponent)")
            return 
        }

        print("🔊 [VoiceoverCache] Downloading: \(remote.absoluteString)")
        var request = URLRequest(url: remote)
        request.cachePolicy = .reloadIgnoringLocalCacheData // Ensure fresh download for prefetch
        request.timeoutInterval = 60 // Increased timeout for slower connections

        let (data, response) = try await URLSession.shared.data(for: request)
        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            print("❌ [VoiceoverCache] Download failed (\(http.statusCode)): \(remote.absoluteString)")
            throw URLError(.badServerResponse)
        }
        try data.write(to: destination, options: .atomic)
        print("✅ [VoiceoverCache] Saved to disk: \(destination.lastPathComponent)")
    }

    /// URL to pass to `AVPlayer`: local copy when prefetched, otherwise the remote URL.
    static func playbackURL(forRemote remote: URL) -> URL {
        if let local = cachedFileURL(forRemote: remote) {
            print("🚀 [VoiceoverCache] Playing from OFFLINE CACHE")
            return local
        } else {
            print("🌐 [VoiceoverCache] Playing from REMOTE STREAM")
            return remote
        }
    }
}
