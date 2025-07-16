//
//  AuthService.swift
//  CyberPilot
//
//  Created by Aleksandr Chumakov on 20/01/25.
//

import Foundation


final class AuthService: ObservableObject {
    @Published var userLogin: String = ""
    @Published var isAuthenticated = false
    @Published var isPhoneNumber = false

    @Published var token: String? {
        didSet {
            if let token = token {
                KeychainService.shared.saveAccessToken(token)
            } else {
                KeychainService.shared.deleteAccessToken()
            }
        }
    }
    
    let logger = CustomLogger(logLevel: .info, includeMetadata: false)
    
    init() {
        // Загружаем токен, но не авторизуем пользователя сразу
        logger.info("token successfully loaded")
        self.token = KeychainService.shared.getAccessToken()
        self.isAuthenticated = false  // Явно отключаем авторизацию
    }


    func logout() {
        token = nil
        isAuthenticated = false
        userLogin = ""
    }
}


