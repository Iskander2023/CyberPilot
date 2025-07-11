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
    private weak var authService: AuthService?
    @Published var username = "Alex"
    @Published var password = "Sssssssss"
    @Published var isMailValid = false
    @Published var isPasswordLengthValid = false
    @Published var isPasswordCapitalLetter = false
    var token: String?
    var userName: String?
    let login = "Alex"

    
    var isLoginFormValid: Bool {
        return isMailValid && isPasswordCapitalLetter
    }
    
    private var cancellableSet: Set<AnyCancellable> = []
    
    init(authService: AuthService) {
        self.authService = authService
        
        $username
            .map { $0.range(of: AppConfig.PatternsForInput.passwordPattern, options: .regularExpression) != nil }
            .assign(to: \.isMailValid, on: self)
            .store(in: &cancellableSet)
        
        $password
            .map { $0.count >= 8 }
            .assign(to: \.isPasswordLengthValid, on: self)
            .store(in: &cancellableSet)
        
        $password
            .map { $0.range(of: AppConfig.PatternsForInput.passwordPattern, options: .regularExpression) != nil }
            .assign(to: \.isPasswordCapitalLetter, on: self)
            .store(in: &cancellableSet)
    }
    
    
    func login(email: String, password: String) async throws -> String {

        // Формирование URL
        guard let url = URL(string: AppConfig.Addresses.userLoginUrl) else {
            throw URLError(.badURL)
        }

        // Настройка запроса
        var request = URLRequest(url: url)
        request.httpMethod = AppConfig.HttpMethods.postMethod
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let bodyParameters = [
            "username": username,
            "password": password
        ]
        let bodyString = bodyParameters.map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")" }
            .joined(separator: "&")
        request.httpBody = bodyString.data(using: .utf8)

        logger.info("Отправлено: \(bodyString)")

        // Выполнение запроса
        let (data, response) = try await URLSession.shared.data(for: request)

        // Проверка ответа
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            if let httpResponse = response as? HTTPURLResponse {
                logger.error("Ошибка сервера: \(httpResponse.statusCode)")
                if httpResponse.statusCode == 422 {
                    throw URLError(.cannotParseResponse, userInfo: ["reason": "Unprocessable Entity: Check request body format"])
                }
            }
            throw URLError(.badServerResponse)
        }
        logger.info("Ответ сервера: \(httpResponse)")

        // Декодирование ответа
        do {
            let authResponse = try JSONDecoder().decode(AuthResponse.self, from: data)
            logger.info("Декодированный ответ: \(authResponse)")

            // Сохранение данных на главном потоке
            await MainActor.run {
                self.authService?.token = authResponse.accessToken
                self.authService?.userLogin = email
                self.authService?.isAuthenticated = true
                self.logger.info(AppConfig.Strings.successfulLogin)
            }

            return authResponse.accessToken
        } catch {
            logger.error("Ошибка декодирования: \(error)")
            throw error
        }
    }
}


struct AuthResponse: Codable {
    let accessToken: String
    let tokenType: String

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case tokenType = "token_type"
    }
}
// Заглушка: тестовый пользователь
//        if email == "newuser@example.com" && password == "DiMeKo2025" {
//            await MainActor.run {
//                self.authService?.isAuthenticated = true
//                self.authService?.userLogin = "Alex"
//                //                socketManager.loginToken = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJlbWFpbCI6Im5ld3VzZXJAZXhhbXBsZS5jb20iLCJ1c2VybmFtZSI6IkFsZXg3NzciLCJpYXQiOjE3NDY0NTQzMjQsImV4cCI6MTc0NjQ1NzkyNH0.Gz6xofMF6D3etHAFhGOlFefQFDaS12pUtmHw2TRv__o"
//            }
//                return "mock_token_for_testuser"
//            }
    //
