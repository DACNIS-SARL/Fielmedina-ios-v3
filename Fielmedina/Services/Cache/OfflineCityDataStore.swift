//
//  OfflineCityDataStore.swift
//  Fielmedina
//
//  Created by Aslan on 2/2/26.
//

import Foundation

final class OfflineCityDataStore {
    static let shared = OfflineCityDataStore()

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
