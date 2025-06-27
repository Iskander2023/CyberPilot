//
//  Keychain.swift
//  CyberPilot
//
//  Created by Aleksandr Chumakov on 27/06/25.
//


import Foundation
import KeychainSwift

final class KeychainService {
    
    static let shared = KeychainService()
    
    private let keychain: KeychainSwift
    
    private init() {
        self.keychain = KeychainSwift()
    }
    
    // MARK: - Keys
    private enum Keys {
        static let accessToken = "accessToken"
        static let refreshToken = "refreshToken"
    }
    
    // MARK: - Access Token
    func saveAccessToken(_ token: String) {
        keychain.set(token, forKey: Keys.accessToken)
    }
    
    func getAccessToken() -> String? {
        return keychain.get(Keys.accessToken)
    }
    
    func deleteAccessToken() {
        keychain.delete(Keys.accessToken)
    }
    
    // MARK: - Refresh Token
    func saveRefreshToken(_ token: String) {
        keychain.set(token, forKey: Keys.refreshToken)
    }
    
    func getRefreshToken() -> String? {
        return keychain.get(Keys.refreshToken)
    }
    
    func deleteRefreshToken() {
        keychain.delete(Keys.refreshToken)
    }
    
    // MARK: - Clear All
    func clearAllTokens() {
        keychain.delete(Keys.accessToken)
        keychain.delete(Keys.refreshToken)
    }
}
