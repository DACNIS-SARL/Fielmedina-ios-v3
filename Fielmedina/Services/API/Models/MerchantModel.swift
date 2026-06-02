//
//  MerchantModel.swift
//  Fielmedina
//
//  Created by Aslan on 6/2/26.
//

import Foundation
import UIKit

struct Merchant: Codable, Identifiable, Hashable {
    let id: String
    let nameEn: String
    let nameFr: String?
    let descriptionEn: String?
    let descriptionFr: String?
    let shortLink: String?
    let latitude: Double?
    let longitude: Double?
    let priceRange: String?
    let openFrom: String?
    let openTo: String?
    let isFeatured: Bool
    let addressEn: String?
    let addressFr: String?
    let phone: String?
    let website: String?
    let category: MerchantCategory?
    let images: [ImageContainer]?
    let products: [MerchantProduct]?
    let ratings: [MerchantRating]?
    let city: MerchantCity?
    
    var displayName: String {
        let isFrench = Locale.current.language.languageCode?.identifier == "fr"
        if isFrench, let nameFr, !nameFr.isEmpty {
            return nameFr
        }
        return nameEn
    }

    var displayDescription: String? {
        let isFrench = Locale.current.language.languageCode?.identifier == "fr"
        if isFrench, let descriptionFr, !descriptionFr.isEmpty {
            return descriptionFr
        }
        return descriptionEn
    }
    
    var displayAddress: String? {
        let isFrench = Locale.current.language.languageCode?.identifier == "fr"
        if isFrench, let addressFr, !addressFr.isEmpty {
            return addressFr
        }
        if let addressEn, !addressEn.isEmpty {
            return addressEn
        }
        return nil
    }

    var imageURL: String? {
        let isPad = UIDevice.current.userInterfaceIdiom == .pad
        if let firstImg = images?.first {
            if isPad {
                return firstImg.image?.url ?? firstImg.imageMobile?.url
            } else {
                return firstImg.imageMobile?.url ?? firstImg.image?.url
            }
        }
        return nil
    }
}

struct MerchantCategory: Codable, Identifiable, Hashable {
    let id: String
    let nameEn: String
    let nameFr: String?
    let icon: String?
    
    var displayName: String {
        let isFrench = Locale.current.language.languageCode?.identifier == "fr"
        if isFrench, let nameFr, !nameFr.isEmpty {
            return nameFr
        }
        return nameEn
    }
}

struct MerchantProduct: Codable, Identifiable, Hashable {
    let id: String
    let nameEn: String
    let nameFr: String?
    let price: Double?
    let image: String?
    
    var displayName: String {
        let isFrench = Locale.current.language.languageCode?.identifier == "fr"
        if isFrench, let nameFr, !nameFr.isEmpty {
            return nameFr
        }
        return nameEn
    }
}

struct MerchantRating: Codable, Identifiable, Hashable {
    let id: String
    let stars: Int
    let reviewerName: String
    let comment: String?
    let createdAt: String
}

struct MerchantCity: Codable, Identifiable, Hashable {
    let id: String
    let nameEn: String?
    let nameFr: String?
    let nameAr: String?
    
    var displayName: String {
        let isFrench = Locale.current.language.languageCode?.identifier == "fr"
        if isFrench, let nameFr, !nameFr.isEmpty {
            return nameFr
        }
        return nameEn ?? ""
    }
}
