//
//  LoginManager.swift
//  CyberPilot
//
//  Created by Aleksandr Chumakov on 9/04/25.
//
import SwiftUI
import Combine


class LoginManager: ObservableObject {
    let logger = CustomLogger(logLevel: .info, includeMetadata: false)
    private weak var stateManager: RobotManager?
    
    @Published var userLogin = "User"
    @Published var password = "Ssssssss"
    
    @Published var isLoginLengthValid = false
    @Published var isPasswordLengthValid = false
    @Published var isPasswordCapitalLetter = false

    var isLoginFormValid: Bool {
        return isLoginLengthValid && isPasswordCapitalLetter
    }

    private var cancellableSet: Set<AnyCancellable> = []

    init(stateManager: RobotManager) {
        self.stateManager = stateManager
        
        $userLogin
                .map { $0.count >= 4 }
                .assign(to: \.isLoginLengthValid, on: self)
                .store(in: &cancellableSet)
            
            $password
                .map { $0.count >= 8 }
                .assign(to: \.isPasswordLengthValid, on: self)
                .store(in: &cancellableSet)
            
            $password
                .map { $0.range(of: "[A-Z]", options: .regularExpression) != nil }
                .assign(to: \.isPasswordCapitalLetter, on: self)
                .store(in: &cancellableSet)
    }


    func login(username: String, password: String) async throws -> String {
        // Заглушка: если тестовый пользователь
        if username == "User" && password == "Ssssssss" {
            await MainActor.run {
                self.stateManager?.isAuthenticated = true
                self.stateManager?.userLogin = username
            }
            return "mock_token_for_testuser"
        }
        //
        guard let url = URL(string: "http://127.0.0.1:8000/users/login") else {
            throw URLError(.badURL)
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = [
            "username": username,
            "password": password
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        let jsonResponse = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let accessToken = jsonResponse?["access_token"] as? String else {
            throw NSError(domain: "LoginError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Token not found in response"])
        }
        await MainActor.run {
            self.logger.info("User login successfully!")
            self.stateManager?.isAuthenticated = true
            self.stateManager?.userLogin = username
        }

        return accessToken
    }
}

