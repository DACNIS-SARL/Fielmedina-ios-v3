//
//  OfflineCityDataStore.swift
//  Fielmedina
//
//  Created by Aslan on 2/2/26.
//

import Foundation
import CoreLocation

final class OfflineCityDataStore {
    static let shared = OfflineCityDataStore()

    struct CachedCity: Codable {
        let id: String
        let cityId: Int32
        let name: String
        let latitude: Double
        let longitude: Double
        let radius: Double
    }

    private let citiesCacheKey = "offline_cities_metadata_cache"

    var cachedCities: [CachedCity] {
        get {
            guard let data = UserDefaults.standard.data(forKey: citiesCacheKey),
                  let cities = try? JSONDecoder().decode([CachedCity].self, from: data) else {
                return [
                    CachedCity(id: "sousse_medina", cityId: 1, name: "Sousse", latitude: 35.825892, longitude: 10.637448, radius: 1500.0),
                    CachedCity(id: "monastir_medina", cityId: 2, name: "Monastir", latitude: 35.7780, longitude: 10.8262, radius: 1500.0),
                    CachedCity(id: "tunis_medina", cityId: 3, name: "Tunis", latitude: 36.7992, longitude: 10.1706, radius: 1500.0)
                ]
            }
            return cities
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                UserDefaults.standard.set(data, forKey: citiesCacheKey)
            }
        }
    }

    func updateCitiesCache(cities: [CachedCity]) {
        self.cachedCities = cities
    }

    /// The closest medina we know about, by great-circle distance.
    ///
    /// Reads `cachedCities`, which the backend populates (`OfflineMapsManager
    /// .refreshCitiesMetadata()` at every launch, plus the Settings screen), so adding
    /// a city server-side makes it a centring candidate with no app release. The
    /// hardcoded trio in `cachedCities` is only the pre-first-sync fallback.
    ///
    /// Every "which medina is the user in / near" decision must go through here —
    /// duplicating the search elsewhere is how the map ended up pinned to three
    /// cities while the rest of the app already knew about more.
    func nearestCity(to coordinate: CLLocationCoordinate2D) -> CachedCity? {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        // Single pass: each candidate's distance is computed once, rather than
        // re-computing both sides on every comparison as a `min(by:)` would.
        var best: (city: CachedCity, distance: CLLocationDistance)?
        for city in cachedCities {
            let distance = location.distance(
                from: CLLocation(latitude: city.latitude, longitude: city.longitude)
            )
            if let current = best, current.distance <= distance { continue }
            best = (city, distance)
        }
        return best?.city
    }

    func getCityId(for coordinate: CLLocationCoordinate2D) -> Int32 {
        nearestCity(to: coordinate)?.cityId ?? 1
    }

    func getCityName(for cityId: Int32) -> String {
        return cachedCities.first(where: { $0.cityId == cityId })?.name ?? "this region"
    }

    private let cityIdsKey = "offline_city_data_ids"
    private let regionMapKey = "offline_city_region_map"

    var downloadedCityIds: Set<Int32> {
        get {
            let stored = UserDefaults.standard.array(forKey: cityIdsKey) as? [Int] ?? []
            return Set(stored.compactMap { Int32(exactly: $0) })
        }
        set {
            let values = newValue.map { Int($0) }
            UserDefaults.standard.set(values, forKey: cityIdsKey)
        }
    }

    func hasCityData(cityId: Int32) -> Bool {
        downloadedCityIds.contains(cityId)
    }

    func markCityDataDownloaded(cityId: Int32, regionId: String? = nil) {
        var updated = downloadedCityIds
        updated.insert(cityId)
        downloadedCityIds = updated

        if let regionId {
            var map = regionCityMap
            map[regionId] = cityId
            regionCityMap = map
        }
    }

    func removeCityData(for regionId: String) {
        var map = regionCityMap
        if let cityId = map[regionId] {
            var updated = downloadedCityIds
            updated.remove(cityId)
            downloadedCityIds = updated
        }
        map.removeValue(forKey: regionId)
        regionCityMap = map
    }

    func cityId(for regionId: String) -> Int32? {
        regionCityMap[regionId]
    }

    private var regionCityMap: [String: Int32] {
        get {
            let stored = UserDefaults.standard.dictionary(forKey: regionMapKey) as? [String: Int] ?? [:]
            var result: [String: Int32] = [:]
            for (key, value) in stored {
                result[key] = Int32(value)
            }
            return result
        }
        set {
            let stored = newValue.mapValues { Int($0) }
            UserDefaults.standard.set(stored, forKey: regionMapKey)
        }
    }
}
