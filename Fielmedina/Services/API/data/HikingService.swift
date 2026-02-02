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
        var allTrails: [Hiking] = []
        var currentOffset = offset ?? 0
        let batchSize = max(limit, 50)

        while true {
            let page = try await fetchHikingsPage(
                cityId: cityId,
                limit: batchSize,
                offset: currentOffset
            )
            allTrails.append(contentsOf: page)

            if page.count < batchSize {
                break
            }
            currentOffset += batchSize
        }

        return allTrails
    }

    private func fetchHikingsPage(
        cityId: Int32?,
        limit: Int32,
        offset: Int32
    ) async throws -> [Hiking] {
        let query = FielmedinaAPI.GetHikingTrailsQuery(
            cityId: cityId != nil ? .some(cityId!) : .none,
            limit: .some(limit),
            offset: .some(offset)
        )

        let data = try await apollo.fetchNetworkAware(query: query)

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
                                longitude: Double(loc.longitude) ?? 0,
                                category: loc.category.map { cat in
                                    LocationCategory(
                                        id: cat.id,
                                        nameEn: cat.nameEn,
                                        nameFr: cat.nameFr
                                    )
                                },
                                images: loc.images.map { image in
                                    ImageContainer(
                                        image: ImageField(url: image.image.url),
                                        imageMobile: image.imageMobile.map { ImageField(url: $0.url) }
                                    )
                                },
                                storyEn: loc.storyEn,
                                storyFr: loc.storyFr
                            )
                        }()
                    )
                }
            )
        }
    }
}
