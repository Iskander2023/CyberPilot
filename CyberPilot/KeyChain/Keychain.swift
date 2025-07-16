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
    
    //  Keys
    private enum Keys {
        static let accessToken = "accessToken"
    }
    
    //  Access Token
    func saveAccessToken(_ token: String) {
        keychain.set(token, forKey: Keys.accessToken)
    }
    
    func getAccessToken() -> String? {
        return keychain.get(Keys.accessToken)
    }
    
    func deleteAccessToken() {
        keychain.delete(Keys.accessToken)
    }
    
    
    // MARK: - Clear All
    func clearToken() {
        keychain.delete(Keys.accessToken)
    }
}
