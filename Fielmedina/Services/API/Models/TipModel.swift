//
//  TipModel.swift
//  Fielmedina
//
//  Created by Aslan on 1/16/26.
//

import Foundation

struct Tip: Codable, Identifiable {
    let id: String
    let descriptionEn: String
    let descriptionFr: String
    
    var displayDescription: String {
        let isFrench = Locale.current.language.languageCode?.identifier == "fr"
        if isFrench && !descriptionFr.isEmpty {
            return descriptionFr
        }
        return descriptionEn
    }
}
