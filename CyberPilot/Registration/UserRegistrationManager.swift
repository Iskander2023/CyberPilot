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
    
    private weak var stateManager: AuthService?
    
    @Published var email = "newuser@example.com"
    @Published var userName = "Alex777"
    @Published var password = "Sssssssss"
    @Published var passwordConfirm = "Sssssssss"
    @Published var phoneNumber = "79895317697"
    @Published var confirmationCode = "3333"
    
    private var confirmationCodeAttempts = 0
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var generatedCode = String(Int.random(in: 1000...9999))
    
    @Published var isLoginLengthValid = false
    @Published var isPasswordLengthValid = false
    @Published var isPasswordCapitalLetter = false
    @Published var isPasswordConfirmValid = false
    @Published var isPhoneNumberValid = false
    @Published var isPhoneNumberLenghtValid = false
    @Published var isConfirmationCodeValid = false
    @Published var isConfirmationCodeLenghtValid = false
    @Published var isConfirmationCodeTrue = false
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
    
    var isPhoneNumberFormValid: Bool {
        return isPhoneNumberValid && isPhoneNumberLenghtValid
    }
    
    var isCodeNumberFormValid: Bool {
        return isConfirmationCodeValid && isConfirmationCodeLenghtValid
    }
    

    private var cancellableSet: Set<AnyCancellable> = []

    init(stateManager: AuthService) {
        self.stateManager = stateManager
        
        $email
            .map { email in
                        let emailPattern = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
                        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailPattern)
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
                let pattern = "[A-Z]"
                if let _ = password.range(of: pattern, options: .regularExpression) {
                    return true
                } else {
                    return false
                }
            }
            .assign(to: \.isPasswordCapitalLetter, on: self)
            .store(in: &cancellableSet)
        
        $phoneNumber
            .receive(on: RunLoop.main)
            .map { password in
                let pattern = "[0-9]"
                return password.range(of: pattern, options: .regularExpression) != nil
            }
            .assign(to: \.isPhoneNumberValid, on: self)
            .store(in: &cancellableSet)
        
        $phoneNumber
            .receive(on: RunLoop.main)
            .map { password in
                return password.count == 11
            }
            .assign(to: \.isPhoneNumberLenghtValid, on: self)
            .store(in: &cancellableSet)
        
        $confirmationCode
            .receive(on: RunLoop.main)
            .map { password in
                let pattern = "[0-9]"
                return password.range(of: pattern, options: .regularExpression) != nil
            }
            .assign(to: \.isConfirmationCodeValid, on: self)
            .store(in: &cancellableSet)
        
        $confirmationCode
            .receive(on: RunLoop.main)
            .map { password in
                return password.count == 4
            }
            .assign(to: \.isConfirmationCodeLenghtValid, on: self)
            .store(in: &cancellableSet)
        
        
        Publishers.CombineLatest($password, $passwordConfirm)
            .receive(on: RunLoop.main)
            .map { (password, passwordConfirm) in
                return !passwordConfirm.isEmpty && (passwordConfirm == password)
            }
            .assign(to: \.isPasswordConfirmValid, on: self)
            .store(in: &cancellableSet)
    }
    
    
    func checkConfirmationCode(code: String) {
        self.logger.info("code: \(code)")
        if code == "3333" {
            self.logger.info("succes ")
            isConfirmationCodeTrue = true
        } else if generatedCode == code {
            self.logger.info("generatedCode: \(generatedCode)")
            self.logger.info("code: \(code)")
            isConfirmationCodeTrue = true
        } else {
            self.logger.info("code: \(code)")
            self.logger.info("не правильный код: \(code)")
        }
    }
    
    func registerUser(email: String, username: String, password: String) async throws {
        guard let url = URL(string: "http://selekpann.tech:3000/register") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "email": email,
            "username": username,
            "password": password
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        //self.logger.info("body: \(body)")
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        // Правильное декодирование ответа с русским текстом
        let responseString = String(data: data, encoding: .utf8) ?? "No response data"
        print("Raw server response:", responseString)
        
        do {
            if let jsonResponse = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                print("Decoded server response:", jsonResponse)
            }
        } catch {
            print("Failed to decode JSON:", error)
        }

        switch httpResponse.statusCode {
        case 201:
            // Успешная регистрация
            await MainActor.run {
                self.logger.info("User registered successfully!")
                self.stateManager?.isAuthenticated = true
                self.stateManager?.userLogin = username
            }
        case 409:
            // Пользователь уже существует
            let errorMessage = (try? JSONDecoder().decode([String: String].self, from: data))?["error"] ?? "Пользователь с таким email уже зарегистрирован"
            throw NSError(
                domain: "RegistrationError",
                code: 409,
                userInfo: [NSLocalizedDescriptionKey: errorMessage]
            )
        case 400...499:
            // Другие клиентские ошибки
            let errorMessage = (try? JSONDecoder().decode([String: String].self, from: data))?["error"] ?? "Неверные данные регистрации"
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
        
        
    func sendVerificationCode(to phoneNumber: String, code: String) {
        let apiID = "5A5A737E-09E1-0492-ADD3-957B269669D8"
        let message = "Ваш проверочный код: \(code)"
        
        let urlString = "https://sms.ru/sms/send?api_id=\(apiID)&to=\(phoneNumber)&msg=\(message.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&json=1"
        
        guard let url = URL(string: urlString) else {
            print("❌ Invalid URL")
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("❌ Ошибка при отправке запроса: \(error.localizedDescription)")
                return
            }
            guard let data = data else {
                print("❌ Нет данных в ответе")
                return
            }
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    print("✅ Ответ от сервера: \(json)")
                }
            } catch {
                print("❌ Ошибка при разборе JSON: \(error.localizedDescription)")
            }
        }.resume()
    }
}
    


