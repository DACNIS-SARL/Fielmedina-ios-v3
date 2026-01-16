//
//  EventCategoryService.swift
//  Fielmedina
//
//  Created by Aslan on 1/16/26.
//

import Foundation
import Apollo

class EventCategoryService {
    static let shared = EventCategoryService()
    
    private init() {}
    
    func fetchEventCategories() async throws -> [EventCategory] {
        let query = FielmedinaAPI.GetCityTipsQuery(cityId: nil, limit: nil, offset: nil)
        let result = try await Network.shared.apollo.fetch(query: query)
        
        guard let categories = result.data?.eventCategories else {
            if let errors = result.errors, !errors.isEmpty {
                throw APIError.graphQLErrors(errors)
            }
            throw APIError.noData
        }
        
        return categories.map { category in
            EventCategory(
                id: String(describing: category.id),
                nameEn: category.nameEn,
                nameFr: category.nameFr
            )
        }
    }
}

enum APIError: Error {
    case graphQLErrors([GraphQLError])
    case noData
}
