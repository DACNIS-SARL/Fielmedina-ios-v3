//
//  CategoryModel.swift
//  Fielmedina
//
//  Created by Aslan on 1/16/26.
//

import Foundation

struct LocationCategory: Codable, Identifiable {
    let id: String
    let nameEn: String
    let nameFr: String
    
    var displayName: String {
        let preferredLanguage = Locale.preferredLanguages.first ?? "en"
        if preferredLanguage.hasPrefix("fr") {
            return nameFr.isEmpty ? nameEn : nameFr
        }
        return nameEn.isEmpty ? nameFr : nameEn
    }
}

struct EventCategory: Codable, Identifiable {
    let id: String
    let nameEn: String
    let nameFr: String?
    
    var displayName: String {
        let preferredLanguage = Locale.preferredLanguages.first ?? "en"
        if preferredLanguage.hasPrefix("fr") {
            return nameFr ?? nameEn
        }
        return nameEn.isEmpty ? (nameFr ?? "") : nameEn
    }
}

