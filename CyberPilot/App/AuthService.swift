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

    @Published var accessToken: String? {
        didSet {
            if let token = accessToken {
                KeychainService.shared.saveAccessToken(token)
            } else {
                KeychainService.shared.deleteAccessToken()
            }
        }
    }
    
    @Published var refreshToken: String? {
        didSet {
            if let token = accessToken {
                KeychainService.shared.saveRefreshToken(token)
            } else {
                KeychainService.shared.deleteRefreshToken()
            }
        }
    }
    
    
    let logger = CustomLogger(logLevel: .info, includeMetadata: false)
    
    init() {
        // Загружаем токен, но не авторизуем пользователя сразу
        logger.info("token successfully loaded")
        self.accessToken = KeychainService.shared.getAccessToken()
        self.refreshToken = KeychainService.shared.getRefreshToken()
        self.isAuthenticated = false  // Явно отключаем авторизацию
    }


    func logout() {
        accessToken = nil
        refreshToken = nil
        isAuthenticated = false
        userLogin = ""
    }
}


