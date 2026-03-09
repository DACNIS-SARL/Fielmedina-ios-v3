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
    
    func fetchEvent(id: String) async throws -> Event {
        let query = FielmedinaAPI.GetEventDetailsQuery(id: id)
        let data = try await apollo.fetchNetworkAware(query: query)
        
        guard let gEvent = data.event else {
            throw NSError(domain: "EventService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Event not found"])
        }
        
        return Event(
            id: gEvent.id,
            nameEn: gEvent.nameEn,
            nameFr: gEvent.nameFr,
            descriptionEn: gEvent.descriptionEn,
            descriptionFr: gEvent.descriptionFr,
            shortLink: gEvent.shortLink,
            startDate: gEvent.startDate,
            endDate: gEvent.endDate,
            time: gEvent.time,
            price: String(describing: gEvent.price),
            boost: gEvent.boost,
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
    
    /// Fetches events for a specific city.
    /// - Parameters:
    ///   - cityId: The ID of the city (optional).
    ///   - limit: Number of events to fetch.
    /// - Returns: An array of domain `Event` models.
    func fetchEvents(cityId: Int32? = nil, limit: Int32 = 10, boost: Bool? = nil) async throws -> [Event] {
        var allEvents: [Event] = []
        var currentOffset: Int32 = 0
        let batchSize = max(limit, 50)

        while true {
            let page = try await fetchEventsPage(
                cityId: cityId,
                limit: batchSize,
                offset: currentOffset,
                boost: boost
            )
            allEvents.append(contentsOf: page)

            if page.count < batchSize {
                break
            }
            currentOffset += batchSize
        }

        return allEvents
    }

    private func fetchEventsPage(
        cityId: Int32?,
        limit: Int32,
        offset: Int32,
        boost: Bool?
    ) async throws -> [Event] {
        let query = FielmedinaAPI.GetEventsByCityQuery(
            cityId: cityId != nil ? .init(integerLiteral: cityId!) : .none,
            categoryId: .none,
            limit: .init(integerLiteral: limit),
            offset: .some(offset),
            boost: boost != nil ? .some(boost!) : .none
        )

        let data = try await apollo.fetchNetworkAware(query: query)

        return data.events.map { gEvent in
            Event(
                id: gEvent.id,
                nameEn: gEvent.nameEn,
                nameFr: gEvent.nameFr,
                descriptionEn: gEvent.descriptionEn,
                descriptionFr: gEvent.descriptionFr,
                shortLink: gEvent.shortLink,
                startDate: gEvent.startDate,
                endDate: gEvent.endDate,
                time: gEvent.time,
                price: String(describing: gEvent.price),
                boost: gEvent.boost,
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
