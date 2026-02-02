//
//  LocationCategoryService.swift
//  Fielmedina
//
//  Created by Aslan on 1/27/26.
//

import Foundation
import Apollo

class LocationCategoryService {
    static let shared = LocationCategoryService()
    
    private let apollo = Network.shared.apollo
    
    private init() {}
    
    /// Fetch all location categories from the API (cache-first behavior by Apollo).
    /// Falls back to network automatically if the cache is empty.
    func fetchLocationCategories() async throws -> [LocationCategory] {
        let query = FielmedinaAPI.GetCityTipsQuery(
            cityId: nil,
            limit: .some(50),
            offset: .some(0)
        )
        
        let data = try await apollo.fetchNetworkAware(query: query)
        
        return data.locationCategories.map { category in
            LocationCategory(
                id: String(describing: category.id),
                nameEn: category.nameEn,
                nameFr: category.nameFr
            )
        }
    }
    
    /// Attempts to fetch location categories from the local Apollo cache only.
    /// Returns nil on cache miss so callers can fall back to network or other strategies.
    func fetchLocationCategoriesFromCache() async -> [LocationCategory]? {
        let query = FielmedinaAPI.GetCityTipsQuery(
            cityId: nil,
            limit: .some(50),
            offset: .some(0)
        )
        do {
            if let response = try await apollo.fetch(query: query, cachePolicy: .cacheOnly),
               let data = response.data {
                return data.locationCategories.map { category in
                    LocationCategory(
                        id: String(describing: category.id),
                        nameEn: category.nameEn,
                        nameFr: category.nameFr
                    )
                }
            }
        } catch {
            return nil
        }
        return nil
    }
}

