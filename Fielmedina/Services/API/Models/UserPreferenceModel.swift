//
//  UserPreferenceModel.swift
//  Fielmedina
//
//  Created by Aslan on 1/16/26.
//

import Foundation


struct UserPreferenceInput: Codable {
    let userUid: String
    let firstVisit: Bool
    let travelingWith: String
    let interests: [String]
    let updatedAt: String
}


struct UserPreferenceResponse: Codable {
    let syncUserPreference: SyncResult
}

struct SyncResult: Codable {
    let ok: Bool
}


extension UserPreferenceInput {
    static func create(
        userUid: String,
        firstVisit: Bool,
        travelingWith: String,
        interests: [String]
    ) -> UserPreferenceInput {
        let formatter = ISO8601DateFormatter()
        let timestamp = formatter.string(from: Date())
        
        return UserPreferenceInput(
            userUid: userUid,
            firstVisit: firstVisit,
            travelingWith: travelingWith,
            interests: interests,
            updatedAt: timestamp
        )
    }
}
