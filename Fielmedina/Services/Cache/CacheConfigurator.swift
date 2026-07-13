//
//  CacheConfigurator.swift
//  Fielmedina
//
//  Created by Aslan on 1/26/26.
//

import Foundation
import Apollo
import ApolloSQLite

enum CacheConfigurator {
    private static let cacheFolderName = "FielmedinaCache"
    private static let offlineFolderName = "FielmedinaOffline"
    private static let graphQLCacheFileName = "apollo.sqlite"
    private static let imageCacheDiskPath = "fielmedina-media-cache"

    /// True when this launch had to create the GraphQL cache file from scratch,
    /// meaning previously prefetched offline data is gone and needs a re-download.
    private static var graphQLCacheWasCreatedFresh = false

    /// Returns whether the GraphQL cache had to be recreated this launch, then
    /// clears the flag so the caller only reacts to it once.
    static func consumeGraphQLCacheFreshFlag() -> Bool {
        defer { graphQLCacheWasCreatedFresh = false }
        return graphQLCacheWasCreatedFresh
    }

    static var graphQLCacheFileURL: URL {
        offlineDataDirectoryURL().appendingPathComponent(graphQLCacheFileName)
    }

    static func makeApolloStore() -> ApolloStore {
        let cacheURL = graphQLCacheFileURL
        migrateLegacyGraphQLCacheIfNeeded(to: cacheURL)
        graphQLCacheWasCreatedFresh = !FileManager.default.fileExists(atPath: cacheURL.path)
        do {
            let cache = try SQLiteNormalizedCache(fileURL: cacheURL)
            return ApolloStore(cache: cache)
        } catch {
            return ApolloStore(cache: InMemoryNormalizedCache())
        }
    }

    /// Moves the GraphQL cache from the old purgeable Caches location into Application Support.
    private static func migrateLegacyGraphQLCacheIfNeeded(to newURL: URL) {
        let fileManager = FileManager.default
        guard !fileManager.fileExists(atPath: newURL.path) else { return }

        let legacyURL = cacheDirectoryURL().appendingPathComponent(graphQLCacheFileName)
        // SQLite may keep journal sidecar files next to the database.
        for suffix in ["", "-wal", "-shm"] {
            let source = URL(fileURLWithPath: legacyURL.path + suffix)
            let destination = URL(fileURLWithPath: newURL.path + suffix)
            if fileManager.fileExists(atPath: source.path) {
                try? fileManager.moveItem(at: source, to: destination)
            }
        }
    }

    static func configureURLCache() {
        let memoryCapacity = 50 * 1024 * 1024
        let diskCapacity = 500 * 1024 * 1024
        let cache = URLCache(
            memoryCapacity: memoryCapacity,
            diskCapacity: diskCapacity,
            diskPath: imageCacheDiskPath
        )
        URLCache.shared = cache
    }

    static func makeApolloURLSession() -> URLSession {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30.0
        configuration.requestCachePolicy = .useProtocolCachePolicy
        configuration.urlCache = URLCache.shared
        return URLSession(configuration: configuration)
    }

    /// Durable home for offline data (GraphQL store, voiceovers, media).
    /// Lives in Application Support so iOS never purges it under storage pressure,
    /// and is excluded from iCloud backups since it can be re-downloaded.
    static func offlineDataDirectoryURL() -> URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
        guard var directoryURL = appSupport?.appendingPathComponent(offlineFolderName, isDirectory: true) else {
            return cacheDirectoryURL()
        }

        if !FileManager.default.fileExists(atPath: directoryURL.path) {
            try? FileManager.default.createDirectory(
                at: directoryURL,
                withIntermediateDirectories: true
            )
            var values = URLResourceValues()
            values.isExcludedFromBackup = true
            try? directoryURL.setResourceValues(values)
        }

        return directoryURL
    }

    private static func cacheDirectoryURL() -> URL {
        let cachesDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
        let directoryURL = cachesDirectory?.appendingPathComponent(cacheFolderName, isDirectory: true)
        guard let directoryURL else {
            return FileManager.default.temporaryDirectory
        }

        if !FileManager.default.fileExists(atPath: directoryURL.path) {
            try? FileManager.default.createDirectory(
                at: directoryURL,
                withIntermediateDirectories: true
            )
        }

        return directoryURL
    }
}
