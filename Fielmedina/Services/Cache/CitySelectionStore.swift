//
//  CitySelectionStore.swift
//  Fielmedina
//
//  Created by Aslan on 1/26/26.
//

import Foundation

final class CitySelectionStore {
    static let shared = CitySelectionStore()

    private let cityIdKey = "offline_selected_city_id"

    var cityId: Int32? {
        get {
            let stored = UserDefaults.standard.integer(forKey: cityIdKey)
            return stored == 0 ? nil : Int32(stored)
        }
        set {
            if let newValue {
                UserDefaults.standard.set(Int(newValue), forKey: cityIdKey)
            } else {
                UserDefaults.standard.removeObject(forKey: cityIdKey)
            }
        }
    }
}
