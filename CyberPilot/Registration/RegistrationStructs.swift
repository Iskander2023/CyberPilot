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
