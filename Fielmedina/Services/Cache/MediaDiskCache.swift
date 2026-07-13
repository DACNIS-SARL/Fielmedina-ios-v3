//
//  MediaDiskCache.swift
//  Fielmedina
//

import CryptoKit
import Foundation

/// Persists prefetched images under Application Support so they survive iOS purging
/// the Caches directory. `URLCache` remains the fast first-level cache; this is the
/// durable fallback that guarantees offline availability.
enum MediaDiskCache {
    private static let subdirectory = "Media"

    private static var directoryURL: URL {
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
        return directoryURL.appendingPathComponent(hex)
    }

    static func cachedData(forRemote remote: URL) -> Data? {
        try? Data(contentsOf: fileURL(forRemote: remote))
    }

    static func hasCachedData(forRemote remote: URL) -> Bool {
        FileManager.default.fileExists(atPath: fileURL(forRemote: remote).path)
    }

    static func store(_ data: Data, forRemote remote: URL) {
        try? data.write(to: fileURL(forRemote: remote), options: .atomic)
    }
}
