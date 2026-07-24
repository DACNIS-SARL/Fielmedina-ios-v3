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
    let city: LocationCity?
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
        let en = voiceoverEn.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.flatMap { $0.isEmpty ? nil : $0 }
        let fr = voiceoverFr.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.flatMap { $0.isEmpty ? nil : $0 }
        if isFrench {
            if let fr { return fr }
            if let en { return en }
            return nil
        }
        if let en { return en }
        if let fr { return fr }
        return nil
    }
    
    /// True when the location has at least one non-empty voiceover asset (any language).
    var hasVoiceover: Bool {
        let en = voiceoverEn.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.flatMap { $0.isEmpty ? nil : $0 }
        let fr = voiceoverFr.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.flatMap { $0.isEmpty ? nil : $0 }
        return en != nil || fr != nil
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

struct LocationCity: Codable, Identifiable, Hashable {
    let id: String
    let nameEn: String?
    let nameFr: String?

    var displayName: String {
        let isFrench = Locale.current.language.languageCode?.identifier == "fr"
        if isFrench, let nameFr, !nameFr.isEmpty {
            return nameFr
        }
        return nameEn ?? ""
    }
}
