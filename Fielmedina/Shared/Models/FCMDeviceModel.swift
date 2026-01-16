//
//  FCMDeviceModel.swift
//  Fielmedina
//
//  Created by Aslan on 1/16/26.
//

import Foundation
import UIKit

struct FCMDeviceInput: Codable {
    let registrationId: String
    let type: String
    let userUid: String
    let name: String?
}


struct FCMDeviceResponse: Codable {
    let registerFcmDevice: FCMDeviceResult
}

struct FCMDeviceResult: Codable {
    let message: String?
    let ok: Bool
}


extension FCMDeviceInput {
    static func create(
        fcmToken: String,
        userUid: String,
        deviceName: String? = nil
    ) -> FCMDeviceInput {
        FCMDeviceInput(
            registrationId: fcmToken,
            type: "ios",
            userUid: userUid,
            name: deviceName ?? UIDevice.current.name
        )
    }
}
