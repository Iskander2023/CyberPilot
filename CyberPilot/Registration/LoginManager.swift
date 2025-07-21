//
//  LoginManager.swift
//  CyberPilot
//
//  Created by Aleksandr Chumakov on 9/04/25.
//
import SwiftUI
import Combine

class LoginManager: ObservableObject {
    let logger = CustomLogger(logLevel: .debug, includeMetadata: false)
    private let authService: AuthService
    @Published var username = ""
    @Published var password = ""
    @Published var isUserNameValid = false
    @Published var isPasswordLengthValid = false
    @Published var isPasswordCapitalLetter = false

    
    var isLoginFormValid: Bool {
        return isUserNameValid && isPasswordCapitalLetter
    }
    
    private var cancellableSet: Set<AnyCancellable> = []
    
    init(authService: AuthService) {
        self.authService = authService
        
        self.username = "Alexander"
        self.password = "Sssssssss"
        $username
            .map { $0.range(of: AppConfig.PatternsForInput.usernamePattern, options: .regularExpression) != nil }
            .assign(to: \.isUserNameValid, on: self)
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
    
    
    func login(username: String, password: String) async throws -> String {
        
        // Заглушка: тестовый пользователь
        if username == "Alex" && password == "Sssssssss" {
            await MainActor.run {
                self.authService.isAuthenticated = true
                self.authService.userLogin = "Alex"
                self.authService.token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJlbWFpbCI6Im5ld3VzZXJAZXhhbXBsZS5jb20iLCJ1c2VybmFtZSI6IkFsZXg3NzciLCJpYXQiOjE3NDY0NTQzMjQsImV4cCI6MTc0NjQ1NzkyNH0.Gz6xofMF6D3etHAFhGOlFefQFDaS12pUtmHw2TRv__o"
            }
                return "mock_token_for_testuser"
            }
        
        
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
                self.authService.token = authResponse.accessToken
                self.authService.userLogin = username
                self.authService.isAuthenticated = true
                self.logger.info(AppConfig.Strings.successfulLogin)
            }

            return authResponse.accessToken
        } catch {
            logger.error("Ошибка декодирования: \(error)")
            throw error
        }
    }
}


