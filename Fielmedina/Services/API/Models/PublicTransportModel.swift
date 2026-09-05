//
//  PublicTransportModel.swift
//  Fielmedina
//
//  Created by Aslan on 1/16/26.
//

import Foundation

struct PublicTransport: Codable, Identifiable {
    let id: String
    let busNumber: String
    let publicTransportType: TransportType
    let fromRegionEn: String
    let fromRegionFr: String
    let toRegionEn: String
    let toRegionFr: String
    let times: [TransportTime]?
    let city: TransportCity?
    
    var displayType: String {
        publicTransportType.displayName
    }
    
    var displayRoute: String {
        let isFrench = Locale.current.language.languageCode?.identifier == "fr"
        let from = isFrench ? fromRegionFr : fromRegionEn
        let to = isFrench ? toRegionFr : toRegionEn
        return "\(from) → \(to)"
    }

    var displayCity: String? {
        city?.displayName
    }
    
    var displayTimes: [String] {
        times?.map { $0.time } ?? []
    }
}

struct TransportType: Codable {
    let nameEn: String
    let nameFr: String
    
    var displayName: String {
        let isFrench = Locale.current.language.languageCode?.identifier == "fr"
        return isFrench ? nameFr : nameEn
    }
}

struct TransportCity: Codable, Identifiable {
    let id: String
    let nameEn: String
    let nameFr: String

    var displayName: String {
        let isFrench = Locale.current.language.languageCode?.identifier == "fr"
        return isFrench ? nameFr : nameEn
    }
}

struct TransportTime: Codable {
    let time: String
}
