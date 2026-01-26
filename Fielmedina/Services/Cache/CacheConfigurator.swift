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
    private static let graphQLCacheFileName = "apollo.sqlite"
    private static let imageCacheDiskPath = "fielmedina-media-cache"

    static func makeApolloStore() -> ApolloStore {
        let cacheURL = cacheDirectoryURL().appendingPathComponent(graphQLCacheFileName)
        do {
            let cache = try SQLiteNormalizedCache(fileURL: cacheURL)
            return ApolloStore(cache: cache)
        } catch {
            return ApolloStore(cache: InMemoryNormalizedCache())
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
        configuration.requestCachePolicy = .returnCacheDataElseLoad
        configuration.urlCache = URLCache.shared
        return URLSession(configuration: configuration)
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
