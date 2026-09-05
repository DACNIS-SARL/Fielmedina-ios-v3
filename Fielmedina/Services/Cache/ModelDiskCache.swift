//
//  ModelDiskCache.swift
//  Fielmedina
//
//  Persists landmark `.glb` models under Application Support so Mapbox's `ModelLayer`
//  can render them with zero signal. Mirrors `VoiceoverDiskCache` deliberately — same
//  hashing, same directory root, same "download once, reuse forever" contract.
//
//  Why a dedicated cache rather than `MediaDiskCache`:
//   - Mapbox is handed a `file://` URI, not `Data`, so the cache must expose a real
//     path. `MediaDiskCache.fileURL` is private and returns extension-less files.
//   - The extension matters: the renderer picks its glTF loader from `.glb`.
//
//  The same files are the intended source for the AR feature, which is why they live
//  in durable storage rather than anything iOS may purge.
//

import CryptoKit
import Foundation

enum ModelDiskCache {
    private static let subdirectory = "Models3D"

    private static var directoryURL: URL {
        let dir = CacheConfigurator.offlineDataDirectoryURL()
            .appendingPathComponent(subdirectory, isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    /// Content-addressed by remote URL, so a re-uploaded model lands on a new path and
    /// is picked up without any cache-busting logic.
    private static func fileURL(forRemote remote: URL) -> URL {
        let digest = SHA256.hash(data: Data(remote.absoluteString.utf8))
        let hex = digest.map { String(format: "%02x", $0) }.joined()
        return directoryURL.appendingPathComponent("\(hex).glb")
    }

    /// Local file, or nil when this model hasn't been prefetched yet.
    static func cachedFileURL(forRemote remote: URL) -> URL? {
        let local = fileURL(forRemote: remote)
        return FileManager.default.fileExists(atPath: local.path) ? local : nil
    }

    /// True when the URL string points at a model we already hold on disk.
    static func cachedFileURL(forRemoteString remote: String) -> URL? {
        guard let url = URL(string: remote) else { return nil }
        return cachedFileURL(forRemote: url)
    }

    /// Writes the remote model to disk if missing. Safe to call from the prefetcher.
    static func downloadIfNeeded(remote: URL) async throws {
        let destination = fileURL(forRemote: remote)
        guard !FileManager.default.fileExists(atPath: destination.path) else { return }

        var request = URLRequest(url: remote)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.timeoutInterval = 120   // models are larger than audio

        let (data, response) = try await URLSession.shared.data(for: request)
        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            throw URLError(.badServerResponse)
        }
        try data.write(to: destination, options: .atomic)
        LogUtils.d("ModelDiskCache", "Saved model: \(destination.lastPathComponent) (\(data.count / 1024) KB)")
    }

    /// True when `url` looks like a 3D model asset, used to route prefetch downloads.
    static func isModelAsset(_ url: URL) -> Bool {
        let path = url.path.lowercased()
        return path.hasSuffix(".glb") || path.hasSuffix(".gltf") || path.contains("/models/")
    }
}
