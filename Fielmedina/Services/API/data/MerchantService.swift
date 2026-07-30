//
//  MerchantService.swift
//  Fielmedina
//
//  Created by Aslan on 6/2/26.
//

import Foundation
import Apollo

class MerchantService {
    static let shared = MerchantService()
    
    private let apollo = Network.shared.apollo
    
    func fetchMerchant(id: String) async throws -> Merchant {
        let query = FielmedinaAPI.GetMerchantDetailsQuery(id: id)
        let data = try await apollo.fetchNetworkAware(query: query)
        
        guard let gMerchant = data.merchant else {
            throw NSError(domain: "MerchantService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Merchant not found"])
        }
        
        return mapMerchantDetail(gMerchant)
    }
    
    func fetchMerchants(
        cityId: Int32? = nil,
        categoryId: Int32? = nil,
        limit: Int32 = 10,
        offset: Int32 = 0,
        forceRefresh: Bool = false
    ) async throws -> [Merchant] {
        var allMerchants: [Merchant] = []
        // Starting point for paging. Defaults to 0, so existing callers (including the
        // offline prefetcher's cache-warming variants) behave exactly as before.
        var currentOffset: Int32 = offset
        let batchSize: Int32 = 50
        
        while allMerchants.count < limit {
            let remaining = limit - Int32(allMerchants.count)
            let currentLimit = min(batchSize, remaining)
            
            let page = try await fetchMerchantsPage(
                cityId: cityId,
                categoryId: categoryId,
                limit: currentLimit,
                offset: currentOffset,
                forceRefresh: forceRefresh
            )
            allMerchants.append(contentsOf: page)
            
            if page.count < currentLimit {
                break
            }
            currentOffset += Int32(page.count)
        }

        return allMerchants
    }

    private func fetchMerchantsPage(
        cityId: Int32?,
        categoryId: Int32?,
        limit: Int32,
        offset: Int32,
        forceRefresh: Bool = false
    ) async throws -> [Merchant] {
        let query = FielmedinaAPI.GetMerchantsByCityQuery(
            cityId: cityId != nil ? .init(integerLiteral: cityId!) : .none,
            categoryId: categoryId != nil ? .init(integerLiteral: categoryId!) : .none,
            limit: .init(integerLiteral: limit),
            offset: .some(offset)
        )

        let data = forceRefresh
            ? try await apollo.fetchFresh(query: query)
            : try await apollo.fetchNetworkAware(query: query)

        return data.merchants.map { mapMerchantSummary($0) }
    }
    
    private func mapMerchantSummary(_ gMerchant: FielmedinaAPI.GetMerchantsByCityQuery.Data.Merchant) -> Merchant {
        Merchant(
            id: gMerchant.id,
            nameEn: gMerchant.nameEn,
            nameFr: gMerchant.nameFr,
            descriptionEn: gMerchant.descriptionEn,
            descriptionFr: gMerchant.descriptionFr,
            shortLink: gMerchant.shortLink,
            latitude: gMerchant.latitude,
            longitude: gMerchant.longitude,
            priceRange: gMerchant.priceRange,
            openFrom: gMerchant.openFrom,
            openTo: gMerchant.openTo,
            isFeatured: gMerchant.isFeatured,
            addressEn: gMerchant.addressEn,
            addressFr: gMerchant.addressFr,
            phone: gMerchant.phone,
            website: gMerchant.website,
            category: gMerchant.category.map { cat in
                MerchantCategory(id: cat.id, nameEn: cat.nameEn, nameFr: cat.nameFr, icon: cat.icon)
            },
            images: gMerchant.images.map { img in
                ImageContainer(
                    image: ImageField(url: img.image.url),
                    imageMobile: img.imageMobile.map { ImageField(url: $0.url) }
                )
            },
            products: nil,
            ratings: nil,
            city: gMerchant.city.map { city in
                MerchantCity(id: city.id, nameEn: city.nameEn, nameFr: city.nameFr, nameAr: city.nameAr)
            }
        )
    }
    
    private func mapMerchantDetail(_ gMerchant: FielmedinaAPI.GetMerchantDetailsQuery.Data.Merchant) -> Merchant {
        Merchant(
            id: gMerchant.id,
            nameEn: gMerchant.nameEn,
            nameFr: gMerchant.nameFr,
            descriptionEn: gMerchant.descriptionEn,
            descriptionFr: gMerchant.descriptionFr,
            shortLink: gMerchant.shortLink,
            latitude: gMerchant.latitude,
            longitude: gMerchant.longitude,
            priceRange: gMerchant.priceRange,
            openFrom: gMerchant.openFrom,
            openTo: gMerchant.openTo,
            isFeatured: gMerchant.isFeatured,
            addressEn: gMerchant.addressEn,
            addressFr: gMerchant.addressFr,
            phone: gMerchant.phone,
            website: gMerchant.website,
            category: gMerchant.category.map { cat in
                MerchantCategory(id: cat.id, nameEn: cat.nameEn, nameFr: cat.nameFr, icon: cat.icon)
            },
            images: gMerchant.images.map { img in
                ImageContainer(
                    image: ImageField(url: img.image.url),
                    imageMobile: img.imageMobile.map { ImageField(url: $0.url) }
                )
            },
            products: gMerchant.products.map { prod in
                MerchantProduct(id: prod.id, nameEn: prod.nameEn, nameFr: prod.nameFr, price: prod.price, image: prod.image)
            },
            ratings: gMerchant.ratings.map { rat in
                MerchantRating(id: rat.id, stars: rat.stars, reviewerName: rat.reviewerName, comment: rat.comment, createdAt: rat.createdAt)
            },
            city: gMerchant.city.map { city in
                MerchantCity(id: city.id, nameEn: city.nameEn, nameFr: city.nameFr, nameAr: city.nameAr)
            }
        )
    }
}
