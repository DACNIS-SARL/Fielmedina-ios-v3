//
//  LocationModel.swift
//  Fielmedina
//
//  Created by Aslan on 1/16/26.
//

import Foundation

struct Location: Codable, Identifiable {
    let id: String
    let nameEn: String
    let nameFr: String
    let latitude: Double
    let longitude: Double
    let category: LocationCategory?
    let images: [ImageContainer]?
    let openFrom: String?
    let openTo: String?
    let storyEn: String?
    let storyFr: String?
    let admissionFee: String?
    let closedDays: [ClosedDay]?
    
    var displayName: String {
        nameFr.isEmpty ? nameEn : nameFr
    }
    
    var displayStory: String? {
        storyFr ?? storyEn
    }
    
    var imageURL: String? {
        images?.first?.displayURL
    }
    
    var displayAdmission: String {
        if let fee = admissionFee, !fee.isEmpty, fee != "0" {
            return fee
        }
        return "Free"
    }
    
    var isFree: Bool {
        admissionFee == nil || admissionFee == "0" || admissionFee?.isEmpty == true
    }
    
    var displaySchedule: String? {
        guard let from = openFrom, let to = openTo else { return nil }
        return "\(from) - \(to)"
    }
}

struct ClosedDay: Codable {
    let day: String
}
