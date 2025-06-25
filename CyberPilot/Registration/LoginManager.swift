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
    @Published var email = "newuser@example.com"
    @Published var password = "DiMeKo2025"
    @Published var isMailValid = false
    @Published var isPasswordLengthValid = false
    @Published var isPasswordCapitalLetter = false
    var token: String?
    var userName: String?
    

    
    var isLoginFormValid: Bool {
        return isMailValid && isPasswordCapitalLetter
    }
    
    private var cancellableSet: Set<AnyCancellable> = []
    
    init(authService: AuthService) {
        self.authService = authService
        
        $email
            .map { email in
                let emailPredicate = NSPredicate(format:"SELF MATCHES %@", AppConfig.PatternsForInput.emailPattern)
                return emailPredicate.evaluate(with: email)
            }
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
        
        // Заглушка: тестовый пользователь
        if email == "newuser@example.com" && password == "DiMeKo2025" {
            await MainActor.run {
                self.authService?.isAuthenticated = true
                self.authService?.userLogin = "Alex"
                //                socketManager.loginToken = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJlbWFpbCI6Im5ld3VzZXJAZXhhbXBsZS5jb20iLCJ1c2VybmFtZSI6IkFsZXg3NzciLCJpYXQiOjE3NDY0NTQzMjQsImV4cCI6MTc0NjQ1NzkyNH0.Gz6xofMF6D3etHAFhGOlFefQFDaS12pUtmHw2TRv__o"
            }
                return "mock_token_for_testuser"
            }
            //
            
        guard let url = URL(string: AppConfig.Addresses.userLoginUrl) else {
                throw URLError(.badURL)
            }
            var request = URLRequest(url: url)
        request.httpMethod = AppConfig.HttpMethods.postMethod
        request.setValue(AppConfig.HttpMethods.httpRequestValue, forHTTPHeaderField: AppConfig.HttpMethods.httpRequestHeader)
            let body: [String: Any] = [
                "email": email,
                "password": password
            ]
            logger.info("отправлено \(body)")
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                throw URLError(.badServerResponse)
            }
            logger.info("\(httpResponse)")
            do {
                let response = try JSONDecoder().decode(UserResponse.self, from: data)
                logger.info("\(response)")
                self.token = response.token
                self.userName = response.user.username
                logger.info("\(String(describing: token)), \(String(describing: userName))")
            } catch {
                logger.info("Error decoding: \(error)")
            }
            
            await MainActor.run {
                self.logger.info(AppConfig.Strings.successfulLogin)
                self.authService?.token = token
                self.authService?.userLogin = userName ?? AppConfig.UsersData.defaultUserName
                self.authService?.isAuthenticated = true
                
            }
            return token ?? ""
    }
}

