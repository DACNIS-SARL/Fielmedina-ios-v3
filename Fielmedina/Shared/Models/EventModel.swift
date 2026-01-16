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
    let startDate: String
    let endDate: String?
    let time: String?
    let price: String?
    let images: [ImageContainer]?
    let location: EventLocation?
    let category: EventCategory?
    
    var displayName: String {
        nameFr ?? nameEn
    }
    
    var displayPrice: String {
        if let price = price, !price.isEmpty {
            // Check if price is essentially zero (0, 0.0, 0.00, etc.)
            let numericPrice = Double(price) ?? -1
            if numericPrice > 0 {
                return price + " TND"
            }
        }
        return "Free"
    }
    
    var displayDate: String {
        if let time = time {
            return "\(formatDate(startDate)), \(formatTime(time))"
        }
        return formatDate(startDate)
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
}

struct EventLocation: Codable, Identifiable {
    let id: String
    let nameEn: String
    let nameFr: String?
    
    var displayName: String {
        nameFr ?? nameEn
    }
}
