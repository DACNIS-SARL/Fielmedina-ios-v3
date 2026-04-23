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
            },
            city: gEvent.city.map { city in
                EventCity(id: city.id, nameEn: city.nameEn, nameFr: city.nameFr, nameAr: city.nameAr)
            }
        )
    }
    
    /// Fetches events for a specific city.
    /// - Parameters:
    ///   - cityId: The ID of the city (optional).
    ///   - limit: Number of events to fetch.
    /// - Returns: An array of domain `Event` models.
    func fetchEvents(cityId: Int32? = nil, limit: Int32 = 10, boost: Bool? = nil, forceRefresh: Bool = false) async throws -> [Event] {
        var allEvents: [Event] = []
        var currentOffset: Int32 = 0
        let batchSize: Int32 = 50
        
        while allEvents.count < limit {
            let remaining = limit - Int32(allEvents.count)
            let currentLimit = min(batchSize, remaining)
            
            let page = try await fetchEventsPage(
                cityId: cityId,
                limit: currentLimit,
                offset: currentOffset,
                boost: boost,
                forceRefresh: forceRefresh
            )
            allEvents.append(contentsOf: page)
            
            if page.count < currentLimit {
                break
            }
            currentOffset += Int32(page.count)
        }

        return allEvents
    }

    private func fetchEventsPage(
        cityId: Int32?,
        limit: Int32,
        offset: Int32,
        boost: Bool?,
        forceRefresh: Bool = false
    ) async throws -> [Event] {
        let query = FielmedinaAPI.GetEventsByCityQuery(
            cityId: cityId != nil ? .init(integerLiteral: cityId!) : .none,
            categoryId: .none,
            limit: .init(integerLiteral: limit),
            offset: .some(offset),
            boost: boost != nil ? .some(boost!) : .none
        )

        let data = forceRefresh
            ? try await apollo.fetchFresh(query: query)
            : try await apollo.fetchNetworkAware(query: query)

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
                },
                city: gEvent.city.map { city in
                    EventCity(id: city.id, nameEn: city.nameEn, nameFr: city.nameFr, nameAr: city.nameAr)
                }
            )
        }
    }
}
