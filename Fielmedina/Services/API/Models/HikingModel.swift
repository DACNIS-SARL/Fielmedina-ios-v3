//
//  HikingModel.swift
//  Fielmedina
//
//  Created by Aslan on 1/16/26.
//

import Foundation

struct Hiking: Codable, Identifiable {
    let id: String
    let nameEn: String
    let nameFr: String
    let descriptionEn: String?
    let descriptionFr: String?
    let city: TrailCity?
    let latitude: Double
    let longitude: Double
    let images: [ImageContainer]?
    let locations: [HikingLocation]?
    
    var displayName: String {
        nameFr.isEmpty ? nameEn : nameFr
    }
    
    var displayDescription: String? {
        descriptionFr ?? descriptionEn
    }

    var cityName: String? {
        city?.displayName
    }
    
    var imageURL: String? {
        images?.first?.displayURL
    }
    
    var orderedLocations: [HikingLocation] {
        locations?.sorted { $0.order < $1.order } ?? []
    }
    
    var waypoints: [TrailWaypoint] {
        orderedLocations.compactMap { hikingLocation in
            guard let loc = hikingLocation.location else { return nil }
            return TrailWaypoint(
                order: hikingLocation.order,
                name: loc.displayName,
                latitude: loc.latitude,
                longitude: loc.longitude,
                images: loc.images,
                storyEn: loc.storyEn,
                storyFr: loc.storyFr
            )
        }
    }
    
    var totalDistance: Double? {
        let points = waypoints
        guard points.count > 1 else { return nil }
        
        var total = 0.0
        for i in 0..<(points.count - 1) {
            total += calculateDistance(
                from: (points[i].latitude, points[i].longitude),
                to: (points[i + 1].latitude, points[i + 1].longitude)
            )
        }
        return total
    }
    
    private func calculateDistance(from: (Double, Double), to: (Double, Double)) -> Double {
        let lat1 = from.0 * .pi / 180
        let lon1 = from.1 * .pi / 180
        let lat2 = to.0 * .pi / 180
        let lon2 = to.1 * .pi / 180
        
        let dLat = lat2 - lat1
        let dLon = lon2 - lon1
        
        let a = sin(dLat / 2) * sin(dLat / 2) +
                cos(lat1) * cos(lat2) *
                sin(dLon / 2) * sin(dLon / 2)
        let c = 2 * atan2(sqrt(a), sqrt(1 - a))
        
        return 6371 * c // Earth radius in km
    }
}

struct HikingLocation: Codable {
    let order: Int
    let location: TrailLocation?
}

struct TrailLocation: Codable, Identifiable {
    let id: String
    let nameEn: String
    let nameFr: String
    let latitude: Double
    let longitude: Double
    let images: [ImageContainer]?
    let storyEn: String?
    let storyFr: String?
    
    var displayName: String {
        nameFr.isEmpty ? nameEn : nameFr
    }
}

struct TrailCity: Codable, Identifiable {
    let id: String
    let nameEn: String
    let nameFr: String

    var displayName: String {
        nameFr.isEmpty ? nameEn : nameFr
    }
}

struct TrailWaypoint {
    let order: Int
    let name: String
    let latitude: Double
    let longitude: Double
    let images: [ImageContainer]?
    let storyEn: String?
    let storyFr: String?
}
