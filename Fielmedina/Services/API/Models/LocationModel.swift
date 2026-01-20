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
    
    var displayAdmission: String? {
        guard let fee = admissionFee, !fee.isEmpty, fee != "0" else {
            return nil
        }
        return fee
    }
    
    var isFree: Bool {
        guard let fee = admissionFee, !fee.isEmpty else {
            return false
        }
        return fee == "0" || fee.lowercased() == "free"
    }
    
    var hasAdmissionInfo: Bool {
        guard let fee = admissionFee, !fee.isEmpty else {
            return false
        }
        return true
    }
    
    var displaySchedule: String? {
        guard let from = openFrom, !from.isEmpty,
              let to = openTo, !to.isEmpty else { return nil }
        return "\(from) - \(to)"
    }
    
    var hasScheduleInfo: Bool {
        displaySchedule != nil
    }
}

struct ClosedDay: Codable {
    let day: String
}
