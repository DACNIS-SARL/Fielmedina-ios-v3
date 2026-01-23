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
        let query = FielmedinaAPI.GetLocationsByCityQuery(
            cityId: cityId != nil ? .some(cityId!) : .none,
            categoryId: categoryId != nil ? .some(categoryId!) : .none,
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
        
        return data.locations.map { gLocation in
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
