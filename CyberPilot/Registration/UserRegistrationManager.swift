//
//  UserRegistrationManager.swift
//  CyberPilot
//
//  Created by Aleksandr Chumakov on 2/04/25.
//

import Foundation
import Combine

class UserRegistrationManager: ObservableObject {
    
    let logger = CustomLogger(logLevel: .info, includeMetadata: false)
    
    private let authService: AuthService
    
    @Published var email = "user@example.com"
    @Published var userName = "Alex"
    @Published var password = "Sssssssss"
    @Published var passwordConfirm = "Sssssssss"

    
    let role: String = "client"
    
    
    @Published var isLoginLengthValid = false
    @Published var isPasswordLengthValid = false
    @Published var isPasswordCapitalLetter = false
    @Published var isPasswordConfirmValid = false
    @Published var isMailValid = false
    

    
    var isRegFormValid: Bool {
        return isLoginLengthValid &&
               isPasswordLengthValid &&
               isPasswordCapitalLetter &&
               isPasswordConfirmValid &&
               isMailValid
    }

    
    var isLoginFormValid: Bool {
        return isLoginLengthValid && isPasswordLengthValid
    }
    

    private var cancellableSet: Set<AnyCancellable> = []
    
    func clearFields() {
        email = ""
        userName = ""
        password = ""
        passwordConfirm = ""
    }


    init(authService: AuthService) {
        self.authService = authService
        
        $email
            .map { email in
                let emailPredicate = NSPredicate(format:"SELF MATCHES %@", AppConfig.PatternsForInput.emailPattern)
                        return emailPredicate.evaluate(with: email)
                    }
                .assign(to: \.isMailValid, on: self)
                .store(in: &cancellableSet)
        
        $userName
            .receive(on: RunLoop.main)
            .map { userLogin in
                return userLogin.count >= 4
            }
            .assign(to: \.isLoginLengthValid, on: self)
            .store(in: &cancellableSet)

        $password
            .receive(on: RunLoop.main)
            .map { password in
                return password.count >= 8
            }
            .assign(to: \.isPasswordLengthValid, on: self)
            .store(in: &cancellableSet)

        $password
            .receive(on: RunLoop.main)
            .map { password in
                if let _ = password.range(of: AppConfig.PatternsForInput.passwordPattern, options: .regularExpression) {
                    return true
                } else {
                    return false
                }
            }
            .assign(to: \.isPasswordCapitalLetter, on: self)
            .store(in: &cancellableSet)
        
        
        Publishers.CombineLatest($password, $passwordConfirm)
            .receive(on: RunLoop.main)
            .map { (password, passwordConfirm) in
                return !passwordConfirm.isEmpty && (passwordConfirm == password)
            }
            .assign(to: \.isPasswordConfirmValid, on: self)
            .store(in: &cancellableSet)
    }
    
    
    // регистрация пользователя
    func registerUser(email: String, username: String, password: String) async throws {
        guard let url = URL(string: AppConfig.Addresses.userRegistrationUrl) else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = AppConfig.HttpMethods.postMethod
        request.setValue(AppConfig.HttpMethods.httpRequestValue, forHTTPHeaderField: AppConfig.HttpMethods.httpRequestHeader)

        let body: [String: Any] = [
            "email": email,
            "login": username,
            "password": password,
            "role": role
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        self.logger.info("body: \(body)")
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        // Правильное декодирование ответа с русским текстом
        let responseString = String(data: data, encoding: .utf8) ?? AppConfig.Strings.responseString
        print("Raw server response:", responseString)
        
        do {
            if let jsonResponse = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let accessToken = jsonResponse["access_token"] as? String {
            
                KeychainService.shared.saveAccessToken(accessToken) // сохранение токена в безопасное хранилище
                
                print("✅ Token saved:", accessToken)
            } else {
                print("⚠️ access_token not found in response")
            }
        } catch {
            print("❌ Failed to decode JSON:", error)
        }


        switch httpResponse.statusCode {
        case 200:
            // Успешная регистрация
            await MainActor.run {
                self.logger.info(AppConfig.Strings.registrationStatusTrue)
                self.authService.isAuthenticated = true
                self.authService.userLogin = username
               
            }
        case 409:
            // Пользователь уже существует
            let errorMessage = (try? JSONDecoder().decode([String: String].self, from: data))?["error"] ?? AppConfig.Strings.alreadyRegistered
            throw NSError(
                domain: "RegistrationError",
                code: 409,
                userInfo: [NSLocalizedDescriptionKey: errorMessage]
            )
        case 400...499:
            // Другие клиентские ошибки
            let errorMessage = (try? JSONDecoder().decode([String: String].self, from: data))?["error"] ?? AppConfig.Strings.incorrectData
            throw NSError(
                domain: "RegistrationError",
                code: httpResponse.statusCode,
                userInfo: [NSLocalizedDescriptionKey: errorMessage]
            )
        case 500...599:
            // Серверные ошибки
            let encodings: [String.Encoding] = [.utf8, .windowsCP1251, .isoLatin1]
                    
            for encoding in encodings {
                if let message = String(data: data, encoding: encoding),
                   !message.contains("???") {
                    throw ServerError.serverError(message: message)
                }
            }
            throw URLError(.badServerResponse)
        default:
            throw URLError(.unknown)
        }
    }
    
    
    enum ServerError: Error {
        case serverError(message: String)
        case networkError(URLError)
        
        var localizedDescription: String {
            switch self {
            case .serverError(let message):
                return message
            case .networkError(let error):
                return error.localizedDescription
            }
        }
    }
        

}
    


