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
    let login_url = "http://selekpann.tech:3000/login"
    @Published var email = "newuser@example.com"
    //    @Published var password = "Sssssssss"
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
                let emailPattern = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
                let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailPattern)
                return emailPredicate.evaluate(with: email)
            }
            .assign(to: \.isMailValid, on: self)
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
    
    
    func login(email: String, password: String) async throws -> String {
        
        // Заглушка: если тестовый пользователь
        if email == "newuser@example.com" && password == "DiMeKo2025" {
            await MainActor.run {
                self.authService?.isAuthenticated = true
                //                socketManager.loginToken = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJlbWFpbCI6Im5ld3VzZXJAZXhhbXBsZS5jb20iLCJ1c2VybmFtZSI6IkFsZXg3NzciLCJpYXQiOjE3NDY0NTQzMjQsImV4cCI6MTc0NjQ1NzkyNH0.Gz6xofMF6D3etHAFhGOlFefQFDaS12pUtmHw2TRv__o"
            }
                return "mock_token_for_testuser"
            }
            //
            
            guard let url = URL(string: login_url) else {
                throw URLError(.badURL)
            }
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
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
                self.logger.info("User login successfully!")
                self.authService?.token = token
                self.authService?.userLogin = userName ?? ""
                self.authService?.isAuthenticated = true
                
            }
            return token ?? ""
    }
}


//class LoginManager: ObservableObject {
//    let logger = CustomLogger(logLevel: .info, includeMetadata: false)
//    private weak var stateManager: RobotManager?
//    let login_url = "http://selekpann.tech:3000/login"
//
//    @Published var email = "newuser@example.com"
////    @Published var password = "Sssssssss"
//    @Published var password = "DiMeKo2025"
//
//    @Published var isMailValid = false
//    @Published var isPasswordLengthValid = false
//    @Published var isPasswordCapitalLetter = false
//    var token: String?
//    var userName: String?
//
//    var isLoginFormValid: Bool {
//        return isMailValid && isPasswordCapitalLetter
//    }
//
//    private var cancellableSet: Set<AnyCancellable> = []
//
//    init(stateManager: RobotManager) {
//        self.stateManager = stateManager
//
//        $email
//            .map { email in
//                        let emailPattern = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
//                        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailPattern)
//                        return emailPredicate.evaluate(with: email)
//                    }
//                .assign(to: \.isMailValid, on: self)
//                .store(in: &cancellableSet)
//
//        $password
//            .map { $0.count >= 8 }
//            .assign(to: \.isPasswordLengthValid, on: self)
//            .store(in: &cancellableSet)
//
//        $password
//            .map { $0.range(of: "[A-Z]", options: .regularExpression) != nil }
//            .assign(to: \.isPasswordCapitalLetter, on: self)
//            .store(in: &cancellableSet)
//    }
//
//
//    func login(email: String, password: String) async throws -> String {
//
//        // Заглушка: если тестовый пользователь
//        if email == "newuser@example.com" && password == "DiMeKo2025" {
//            await MainActor.run {
//                self.stateManager?.isAuthenticated = true
////                self.stateManager?.token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJlbWFpbCI6Im5ld3VzZXJAZXhhbXBsZS5jb20iLCJ1c2VybmFtZSI6IkFsZXg3NzciLCJpYXQiOjE3NDY0NTQzMjQsImV4cCI6MTc0NjQ1NzkyNH0.Gz6xofMF6D3etHAFhGOlFefQFDaS12pUtmHw2TRv__o"
//            }
//            return "mock_token_for_testuser"
//        }
//        //
//
//        guard let url = URL(string: login_url) else {
//            throw URLError(.badURL)
//        }
//        var request = URLRequest(url: url)
//        request.httpMethod = "POST"
//        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
//        let body: [String: Any] = [
//            "email": email,
//            "password": password
//        ]
//        logger.info("отправлено \(body)")
//        request.httpBody = try JSONSerialization.data(withJSONObject: body)
//        let (data, response) = try await URLSession.shared.data(for: request)
//        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
//            throw URLError(.badServerResponse)
//        }
//        logger.info("\(httpResponse)")
//        do {
//            let response = try JSONDecoder().decode(UserResponse.self, from: data)
//            logger.info("\(response)")
//            self.token = response.token
//            self.userName = response.user.username
//            logger.info("\(String(describing: token)), \(String(describing: userName))")
//        } catch {
//            logger.info("Error decoding: \(error)")
//        }
//
//        await MainActor.run {
//            self.logger.info("User login successfully!")
//            self.stateManager?.token = token
//            self.stateManager?.userLogin = userName ?? ""
//            self.stateManager?.isAuthenticated = true
//
//        }
//        return token ?? ""
//    }
// }
//}
