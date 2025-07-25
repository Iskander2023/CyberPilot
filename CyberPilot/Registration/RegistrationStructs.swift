//
//  RegistrationStructs.swift
//  CyberPilot
//
//  Created by Aleksandr Chumakov on 14/05/25.
//

import Foundation

struct UserResponse: Codable {
    let token: String
    let user: User

    struct User: Codable {
        let username: String
    }
}


struct AuthResponse: Codable {
    let accessToken: String
    let tokenType: String
    let refreshToken: String?

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case tokenType = "token_type"
        case refreshToken = "refresh_token" 
    }
}

enum RegistrationStep {
    case phoneInput
    case captcha
    case confirmationCode
    case userRegistrationInput
}
