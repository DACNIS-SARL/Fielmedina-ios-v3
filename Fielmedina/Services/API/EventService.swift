//
//  EventService.swift
//  Fielmedina
//
//  Created by Aslan on 1/16/26.
//

import Foundation
import Apollo

class EventService {
    static let shared = EventService()
    
    private let apollo = Network.shared.apollo
    
    /// Fetches events for a specific city.
    /// - Parameters:
    ///   - cityId: The ID of the city (optional).
    ///   - limit: Number of events to fetch.
    /// - Returns: An array of domain `Event` models.
    func fetchEvents(cityId: Int32? = nil, limit: Int32 = 10) async throws -> [Event] {
        let query = FielmedinaAPI.GetEventsByCityQuery(
            cityId: cityId != nil ? .init(integerLiteral: cityId!) : .none,
            categoryId: .none,
            limit: .init(integerLiteral: limit),
            offset: .none
        )
        
        let graphQLResult = try await apollo.fetch(query: query)
        
        if let errors = graphQLResult.errors {
            let message = errors.map { $0.message ?? "Unknown error" }.joined(separator: ", ")
            throw NSError(domain: "Apollo", code: 1, userInfo: [NSLocalizedDescriptionKey: message])
        }
        
        guard let data = graphQLResult.data else {
            return []
        }
        
        return data.events.map { gEvent in
            Event(
                id: gEvent.id,
                nameEn: gEvent.nameEn,
                nameFr: gEvent.nameFr,
                startDate: gEvent.startDate,
                endDate: gEvent.endDate,
                time: gEvent.time,
                price: String(describing: gEvent.price), // Convert Decimal to String
                images: gEvent.images.map { img in
                    ImageContainer(
                        image: ImageField(url: img.image.url),
                        imageMobile: img.imageMobile.map { ImageField(url: $0.url) }
                    )
                },
                location: gEvent.location.map { loc in
                    EventLocation(id: loc.id, nameEn: loc.nameEn, nameFr: loc.nameFr)
                },
                category: gEvent.category.map { cat in
                    EventCategory(id: cat.id, nameEn: cat.nameEn, nameFr: cat.nameFr)
                }
            )
        }
    }
}
