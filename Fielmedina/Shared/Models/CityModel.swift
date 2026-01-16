//
//  CityModel.swift
//  Fielmedina
//
//  Created by Aslan on 1/16/26.
//

import Foundation

struct City: Codable, Identifiable {
    let id: String
    let nameEn: String
    let nameFr: String
    let nameAr: String
    let regionEn: String
    let regionFr: String
    let regionAr: String
    let countryEn: String
    let countryFr: String
    let countryAr: String
    
    var displayName: String {
        nameFr.isEmpty ? nameEn : nameFr
    }
    
    var displayRegion: String {
        regionFr.isEmpty ? regionEn : regionFr
    }
    
    var displayCountry: String {
        countryFr.isEmpty ? countryEn : countryFr
    }
}
