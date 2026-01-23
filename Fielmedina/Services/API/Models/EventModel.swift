//
//  EventModel.swift
//  Fielmedina
//
//  Created by Aslan on 1/13/26.
//

import Foundation

//struct Event: Identifiable {
//    let id = UUID()
//    let title: String
//    let date: String
//    let price: String
//    let imageName: String
//    let category: String
//    let descripyion: String
//}



// MARK: Production with api

struct Event: Codable, Identifiable {
    let id: String
    let nameEn: String
    let nameFr: String?
    let descriptionEn: String?
    let descriptionFr: String?
    let shortLink: String?
    let startDate: String
    let endDate: String?
    let time: String?
    let price: String?
    let boost: Bool
    let images: [ImageContainer]?
    let location: EventLocation?
    let category: EventCategory?
    
    var displayName: String {
        nameFr ?? nameEn
    }

    var displayDescription: String? {
        descriptionFr ?? descriptionEn
    }

    var resolvedLink: String? {
        shortLink
    }
    
    var displayPrice: String {
        if let price = price, !price.isEmpty {
            // Check if price is essentially zero (0, 0.0, 0.00, etc.)
            let numericPrice = Double(price) ?? -1
            if numericPrice > 0 {
                return price + " TND"
            }
        }
        return String(localized: "Free")
    }
    
    var displayDate: String {
        if let time = time {
            return "\(formatDate(startDate)), \(formatTime(time))"
        }
        return formatDate(startDate)
    }
    
    /// Modern formatted date like "Thu, Feb 13, 8:30PM"
    var displayDateFormatted: String {
        if let time = time {
            return "\(formatDateModern(startDate)), \(formatTimeModern(time))"
        }
        return formatDateModern(startDate)
    }
    
    var imageURL: String? {
        images?.first?.displayURL
    }
    
    var isFree: Bool {
        if let price = price {
            let numericPrice = Double(price) ?? -1
            return numericPrice <= 0
        }
        return true
    }
    
    private func formatDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        if let date = formatter.date(from: dateString) {
            formatter.dateFormat = "EEE, MMM d"
            return formatter.string(from: date)
        }
        return dateString
    }

    private func formatTime(_ timeString: String) -> String {
        let formatter = DateFormatter()
        // Input usually HH:mm:ss
        formatter.dateFormat = "HH:mm:ss"
        
        if let date = formatter.date(from: timeString) {
            formatter.dateFormat = "HH:mm"
            return formatter.string(from: date)
        }
        
        // Fallback for HH:mm input
        formatter.dateFormat = "HH:mm"
        if formatter.date(from: timeString) != nil {
            return timeString
        }

        return timeString
    }
    
    private func formatDateModern(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        if let date = formatter.date(from: dateString) {
            formatter.dateFormat = "EEE, MMM d"
            return formatter.string(from: date)
        }
        return dateString
    }
    
    private func formatTimeModern(_ timeString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        
        if let date = formatter.date(from: timeString) {
            formatter.dateFormat = "h:mma"
            formatter.amSymbol = "AM"
            formatter.pmSymbol = "PM"
            return formatter.string(from: date)
        }
        
        // Fallback for HH:mm input
        formatter.dateFormat = "HH:mm"
        if let date = formatter.date(from: timeString) {
            formatter.dateFormat = "h:mma"
            formatter.amSymbol = "AM"
            formatter.pmSymbol = "PM"
            return formatter.string(from: date)
        }
        
        return timeString
    }
}

struct EventLocation: Codable, Identifiable {
    let id: String
    let nameEn: String
    let nameFr: String?
    
    var displayName: String {
        nameFr ?? nameEn
    }
}
