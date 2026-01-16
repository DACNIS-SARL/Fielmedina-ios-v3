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
    
    var displayType: String {
        publicTransportType.displayName
    }
    
    var displayRoute: String {
        let from = fromRegionFr.isEmpty ? fromRegionEn : fromRegionFr
        let to = toRegionFr.isEmpty ? toRegionEn : toRegionFr
        return "\(from) → \(to)"
    }
    
    var displayTimes: [String] {
        times?.map { $0.time } ?? []
    }
}

struct TransportType: Codable {
    let nameEn: String
    let nameFr: String
    
    var displayName: String {
        nameFr.isEmpty ? nameEn : nameFr
    }
}

struct TransportTime: Codable {
    let time: String
}
