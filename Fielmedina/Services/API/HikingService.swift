//
//  HikingService.swift
//  Fielmedina
//
//  Created by Aslan on 1/22/26.
//

import Foundation
import Apollo

class HikingService {
    static let shared = HikingService()

    private let apollo = Network.shared.apollo

    func fetchHikings(cityId: Int32? = nil, limit: Int32 = 20, offset: Int32? = nil) async throws -> [Hiking] {
        let query = FielmedinaAPI.GetHikingTrailsQuery(
            cityId: cityId != nil ? .some(cityId!) : .none,
            limit: .some(limit),
            offset: offset != nil ? .some(offset!) : .none
        )

        let graphQLResult = try await apollo.fetch(query: query)

        if let errors = graphQLResult.errors {
            let message = errors.map { $0.message ?? "Unknown error" }.joined(separator: ", ")
            throw NSError(domain: "Apollo", code: 1, userInfo: [NSLocalizedDescriptionKey: message])
        }

        guard let data = graphQLResult.data else {
            return []
        }

        return data.hikings.map { hiking in
            Hiking(
                id: hiking.id,
                nameEn: hiking.nameEn,
                nameFr: hiking.nameFr,
                descriptionEn: hiking.descriptionEn,
                descriptionFr: hiking.descriptionFr,
                city: hiking.city.map { city in
                    TrailCity(
                        id: city.id,
                        nameEn: city.nameEn ?? "",
                        nameFr: city.nameFr ?? ""
                    )
                },
                latitude: hiking.latitude ?? 0,
                longitude: hiking.longitude ?? 0,
                images: hiking.images.map { image in
                    ImageContainer(
                        image: ImageField(url: image.image.url),
                        imageMobile: image.imageMobile.map { ImageField(url: $0.url) }
                    )
                },
                locations: hiking.locations.map { location in
                    HikingLocation(
                        order: location.order,
                        location: {
                            let loc = location.location
                            return TrailLocation(
                                id: loc.id,
                                nameEn: loc.nameEn,
                                nameFr: loc.nameFr,
                                latitude: Double(loc.latitude) ?? 0,
                                longitude: Double(loc.longitude) ?? 0
                            )
                        }()
                    )
                }
            )
        }
    }
}
