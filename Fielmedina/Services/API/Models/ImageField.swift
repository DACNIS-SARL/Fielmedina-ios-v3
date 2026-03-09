//
//  ImageField.swift
//  Fielmedina
//
//  Created by Aslan on 1/16/26.
//

import SwiftUI

struct ImageField: Codable, Hashable {
    let url: String
}

struct ImageContainer: Codable, Hashable {
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
