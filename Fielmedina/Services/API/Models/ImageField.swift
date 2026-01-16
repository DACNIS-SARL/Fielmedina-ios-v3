//
//  ImageField.swift
//  Fielmedina
//
//  Created by Aslan on 1/16/26.
//

import Foundation

struct ImageField: Codable {
    let url: String
}

struct ImageContainer: Codable {
    let image: ImageField?
    let imageMobile: ImageField?
    
    var displayURL: String? {
        imageMobile?.url ?? image?.url
    }
}
