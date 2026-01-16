//
//  ForgetMeModel.swift
//  Fielmedina
//
//  Created by Aslan on 1/16/26.
//

import Foundation


struct ForgetMeInput: Codable {
    let userUid: String
}


struct ForgetMeResponse: Codable {
    let forgetMe: ForgetMeResult
}

struct ForgetMeResult: Codable {
    let ok: Bool
}
