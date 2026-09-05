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
        let isFrench = Locale.current.language.languageCode?.identifier == "fr"
        return isFrench ? nameFr : nameEn
    }
    
    var displayRegion: String {
        let isFrench = Locale.current.language.languageCode?.identifier == "fr"
        return isFrench ? regionFr : regionEn
    }
    
    var displayCountry: String {
        let isFrench = Locale.current.language.languageCode?.identifier == "fr"
        return isFrench ? countryFr : countryEn
    }
}
