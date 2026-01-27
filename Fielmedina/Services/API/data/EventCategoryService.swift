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
    
    private let apollo = Network.shared.apollo
    
    private init() {}
    
    func fetchEventCategories() async throws -> [EventCategory] {
        var allCategories: [EventCategory] = []
        var currentOffset: Int32 = 0
        let batchSize: Int32 = 50

        while true {
            let page = try await fetchEventCategoriesPage(
                limit: batchSize,
                offset: currentOffset
            )
            allCategories.append(contentsOf: page)

            if page.count < batchSize {
                break
            }
            currentOffset += batchSize
        }

        return allCategories
    }
    
    private func fetchEventCategoriesPage(
        limit: Int32,
        offset: Int32
    ) async throws -> [EventCategory] {
        let query = FielmedinaAPI.GetCityTipsQuery(
            cityId: nil,
            limit: .some(limit),
            offset: .some(offset)
        )
        
        let response = try await apollo.fetch(query: query)
        
        if let errors = response.errors {
            let message = errors.map { $0.message ?? "Unknown error" }.joined(separator: ", ")
            throw NSError(domain: "Apollo", code: 1, userInfo: [NSLocalizedDescriptionKey: message])
        }
        
        guard let data = response.data else {
            return []
        }
        
        return data.eventCategories.map { category in
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