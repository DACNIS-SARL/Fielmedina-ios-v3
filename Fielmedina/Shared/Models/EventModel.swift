//
//  EventModel.swift
//  Fielmedina
//
//  Created by Aslan on 1/13/26.
//

import Foundation

struct Event: Identifiable {
    let id = UUID()
    let title: String
    let date: String
    let price: String
    let imageName: String
    let category: String
}
