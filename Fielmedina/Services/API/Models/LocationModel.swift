//
//  LocationModel.swift
//  Fielmedina
//
//  Created by Aslan on 1/16/26.
//

import Foundation

struct Location: Codable, Identifiable, Hashable {
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
    let voiceoverEn: String?
    let voiceoverFr: String?
    
    var displayName: String {
        let isFrench = Locale.current.language.languageCode?.identifier == "fr"
        if isFrench && !nameFr.isEmpty {
            return nameFr
        }
        return nameEn
    }
    
    var displayStory: String? {
        let isFrench = Locale.current.language.languageCode?.identifier == "fr"
        if isFrench, let storyFr, !storyFr.isEmpty {
            return storyFr
        }
        return storyEn
    }
    
    var imageURL: String? {
        images?.first?.displayURL
    }
    
    var voiceoverURL: String? {
        let isFrench = Locale.current.language.languageCode?.identifier == "fr"
        if isFrench, let voiceoverFr, !voiceoverFr.isEmpty {
            return voiceoverFr
        }
        return voiceoverEn
    }
    
    var displayAdmission: String? {
        guard let fee = admissionFee, !fee.isEmpty else {
            return nil
        }
        // Don't show price for free entries
        if let numericFee = Double(fee), numericFee == 0 {
            return nil
        }
        return fee
    }
    
    var isFree: Bool {
        guard let fee = admissionFee, !fee.isEmpty else {
            return false
        }
        // Handle "0", "0.00", "0.0", etc.
        if let numericFee = Double(fee) {
            return numericFee == 0
        }
        return fee.lowercased() == "free"
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

struct ClosedDay: Codable, Hashable {
    let day: String
}
