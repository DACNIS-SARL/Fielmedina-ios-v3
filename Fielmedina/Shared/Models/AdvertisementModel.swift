//
//  AdvertisementModel.swift
//  Fielmedina
//
//  Created by Aslan on 1/16/26.
//

import Foundation

struct Advertisement: Codable, Identifiable {
    let id: String
    let name: String
    let link: String?
    let country: AdCountry?
    let city: AdCity?
    let imageMobile: ImageField?
    let imageTablet: ImageField?
    
    var displayImage: String? {
        imageMobile?.url ?? imageTablet?.url
    }
}

struct AdCountry: Codable, Identifiable {
    let id: String
    let name: String
}

struct AdCity: Codable, Identifiable {
    let id: String
    let nameEn: String
}
