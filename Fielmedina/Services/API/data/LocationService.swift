//
//  LocationService.swift
//  Fielmedina
//
//  Created by Aslan on 1/20/26.
//

import Foundation
import Apollo

class LocationService {
    static let shared = LocationService()
    
    private let apollo = Network.shared.apollo
    
    func fetchLocation(id: String) async throws -> Location {
        let query = FielmedinaAPI.GetLocationDetailsQuery(id: id)
        let data = try await apollo.fetchNetworkAware(query: query)
        
        guard let gLocation = data.location else {
            throw NSError(domain: "LocationService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Location not found"])
        }
        
        return Location(
            id: gLocation.id,
            nameEn: gLocation.nameEn,
            nameFr: gLocation.nameFr,
            latitude: Double(gLocation.latitude) ?? 0,
            longitude: Double(gLocation.longitude) ?? 0,
            category: gLocation.category.map { cat in
                LocationCategory(
                    id: cat.id,
                    nameEn: cat.nameEn,
                    nameFr: cat.nameFr
                )
            },
            images: gLocation.images.map { img in
                ImageContainer(
                    image: ImageField(url: img.image.url),
                    imageMobile: img.imageMobile.map { ImageField(url: $0.url) }
                )
            },
            openFrom: gLocation.openFrom.map { formatTime($0) },
            openTo: gLocation.openTo.map { formatTime($0) },
            storyEn: gLocation.storyEn,
            storyFr: gLocation.storyFr,
            admissionFee: gLocation.admissionFee,
            closedDays: nil
        )
    }
    
    /// Fetches locations for a specific city.
    /// - Parameters:
    ///   - cityId: The ID of the city (optional).
    ///   - categoryId: The ID of the category (optional).
    ///   - limit: Number of locations to fetch.
    ///   - offset: Number of locations to skip.
    /// - Returns: An array of domain `Location` models.
    func fetchLocations(
        cityId: Int32? = nil,
        categoryId: Int32? = nil,
        limit: Int32 = 10,
        offset: Int32? = nil
    ) async throws -> [Location] {
        if let offset {
            return try await fetchLocationsPage(
                cityId: cityId,
                categoryId: categoryId,
                limit: limit,
                offset: offset
            )
        }

        var allLocations: [Location] = []
        var currentOffset: Int32 = 0
        let batchSize = max(limit, 50)

        while true {
            let page = try await fetchLocationsPage(
                cityId: cityId,
                categoryId: categoryId,
                limit: batchSize,
                offset: currentOffset
            )
            allLocations.append(contentsOf: page)

            if page.count < batchSize {
                break
            }
            currentOffset += batchSize
        }

        return allLocations
    }

    private func fetchLocationsPage(
        cityId: Int32?,
        categoryId: Int32?,
        limit: Int32,
        offset: Int32
    ) async throws -> [Location] {
        let query = FielmedinaAPI.GetLocationsByCityQuery(
            cityId: cityId != nil ? .some(cityId!) : .none,
            categoryId: categoryId != nil ? .some(categoryId!) : .none,
            limit: .some(limit),
            offset: .some(offset)
        )

        let data = try await apollo.fetchNetworkAware(query: query)

        return data.locations.compactMap { gLocation in
            Location(
                id: gLocation.id,
                nameEn: gLocation.nameEn,
                nameFr: gLocation.nameFr,
                latitude: Double(gLocation.latitude) ?? 0,
                longitude: Double(gLocation.longitude) ?? 0,
                category: gLocation.category.map { cat in
                    LocationCategory(
                        id: cat.id,
                        nameEn: cat.nameEn,
                        nameFr: cat.nameFr
                    )
                },
                images: gLocation.images.map { img in
                    ImageContainer(
                        image: ImageField(url: img.image.url),
                        imageMobile: img.imageMobile.map { ImageField(url: $0.url) }
                    )
                },
                openFrom: gLocation.openFrom.map { formatTime($0) },
                openTo: gLocation.openTo.map { formatTime($0) },
                storyEn: gLocation.storyEn,
                storyFr: gLocation.storyFr,
                admissionFee: gLocation.admissionFee,
                closedDays: nil
            )
        }
    }
    
    /// Formats time string to show only hours and minutes (HH:mm)
    private func formatTime(_ time: String) -> String {
        let components = time.split(separator: ":")
        if components.count >= 2 {
            return "\(components[0]):\(components[1])"
        }
        return time
    }
}
