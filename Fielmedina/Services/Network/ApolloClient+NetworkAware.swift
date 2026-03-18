//
//  ApolloClient+NetworkAware.swift
//  Fielmedina
//
//  Created by Aslan on 2/2/26.
//

import Apollo
import ApolloAPI
import Foundation

extension ApolloClient {
    /// Fetches data using an offline-first strategy.
    /// - Online: returns cached data immediately if available, and refreshes the cache in the background.
    /// - Offline: returns cached data if available, otherwise falls back to a network attempt.
    func fetchNetworkAware<Query: GraphQLQuery>(
        query: Query,
        refreshIfCached: Bool = true
    ) async throws -> Query.Data where Query.ResponseFormat == SingleResponseFormat {
        let isOnline = NetworkMonitor.shared.isConnected

        if isOnline {
            if let cached = try await fetchCachedData(query: query) {
                if refreshIfCached {
                    Task.detached { [weak self] in
                        guard let self else { return }
                        _ = try? await self.fetchData(query: query, cachePolicy: .networkOnly)
                    }
                }
                return cached
            }

            return try await fetchData(query: query, cachePolicy: .networkOnly)
        }

        if let cached = try await fetchCachedData(query: query) {
            return cached
        }

        return try await fetchData(query: query, cachePolicy: .cacheFirst)
    }
    
    /// Network-first fetch used for pull-to-refresh and explicit reload.
    /// - Online: always hits the network and updates the cache.
    /// - Offline: falls back to fetchNetworkAware (cache-first).
    func fetchFresh<Query: GraphQLQuery>(
        query: Query
    ) async throws -> Query.Data where Query.ResponseFormat == SingleResponseFormat {
        if NetworkMonitor.shared.isConnected {
            return try await fetchData(query: query, cachePolicy: .networkOnly)
        }
        return try await fetchNetworkAware(query: query)
    }

    private func fetchCachedData<Query: GraphQLQuery>(
        query: Query
    ) async throws -> Query.Data? where Query.ResponseFormat == SingleResponseFormat {
        guard let response = try await fetch(query: query, cachePolicy: .cacheOnly) else {
            return nil
        }
        return try extractData(from: response, allowEmptyData: true)
    }

    private func fetchData<Query: GraphQLQuery>(
        query: Query,
        cachePolicy: CachePolicy.Query.SingleResponse
    ) async throws -> Query.Data where Query.ResponseFormat == SingleResponseFormat {
        let response = try await fetch(query: query, cachePolicy: cachePolicy)
        guard let data = try extractData(from: response, allowEmptyData: false) else {
            throw NSError(domain: "Apollo", code: 0, userInfo: [NSLocalizedDescriptionKey: "No data"])
        }
        return data
    }

    private func extractData<Query: GraphQLQuery>(
        from response: GraphQLResponse<Query>,
        allowEmptyData: Bool
    ) throws -> Query.Data? where Query.ResponseFormat == SingleResponseFormat {
        if let errors = response.errors {
            let message = errors.map { $0.message ?? "Unknown error" }.joined(separator: ", ")
            throw NSError(domain: "Apollo", code: 1, userInfo: [NSLocalizedDescriptionKey: message])
        }

        if let data = response.data {
            return data
        }

        if allowEmptyData {
            return nil
        }

        throw NSError(domain: "Apollo", code: 0, userInfo: [NSLocalizedDescriptionKey: "No data"])
    }
}

