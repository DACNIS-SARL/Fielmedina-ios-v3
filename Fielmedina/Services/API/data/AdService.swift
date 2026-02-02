//
//  AdService.swift
//  Fielmedina
//
//  Created by Aslan on 1/22/26.
//

import Foundation
import Apollo

class AdService {
    static let shared = AdService()

    private let apollo = Network.shared.apollo

    func fetchAds(countryId: Int32? = nil, cityId: Int32? = nil, limit: Int32 = 10) async throws -> [Advertisement] {
        let query = FielmedinaAPI.GetAdsQuery(
            countryId: countryId != nil ? .some(countryId!) : .none,
            cityId: cityId != nil ? .some(cityId!) : .none,
            limit: .some(limit)
        )

        let data = try await apollo.fetchNetworkAware(query: query)

        return data.ads.map { ad in
            Advertisement(
                id: ad.id,
                name: ad.name ?? "",
                link: ad.link,
                shortLink: ad.shortLink,
                country: ad.country.map { country in
                    AdCountry(id: country.id, name: country.name)
                },
                city: ad.city.map { city in
                    AdCity(id: city.id, nameEn: city.nameEn ?? "")
                },
                imageMobile: ad.imageMobile.map { ImageField(url: $0.url) },
                imageTablet: ad.imageTablet.map { ImageField(url: $0.url) }
            )
        }
    }
}
