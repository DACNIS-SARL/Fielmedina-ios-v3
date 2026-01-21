//
//  ImageField.swift
//  Fielmedina
//
//  Created by Aslan on 1/16/26.
//

import SwiftUI

struct ImageField: Codable {
    let url: String
}

struct ImageContainer: Codable {
    let image: ImageField?
    let imageMobile: ImageField?
    
    var displayURL: String? {
        if UIDevice.current.userInterfaceIdiom == .pad {
            return image?.url ?? imageMobile?.url
        } else {
            return imageMobile?.url ?? image?.url
        }
    }
}
