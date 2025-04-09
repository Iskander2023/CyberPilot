//
//  RegManager.swift
//  Robot_Controller
//
//  Created by Admin on 2/04/25.
//

import Foundation
import Combine

class UserRegistrationManager: ObservableObject {
    
    private weak var stateManager: RobotManager?
    
    @Published var userLogin = ""
    @Published var password = ""
    @Published var passwordConfirm = ""
    @Published var phoneNumber = ""
    @Published var confirmationCode = ""

   
    @Published var isLoginLengthValid = false
    @Published var isPasswordLengthValid = false
    @Published var isPasswordCapitalLetter = false
    @Published var isPasswordConfirmValid = false
    @Published var isPhoneNumberValid = false
    @Published var isPhoneNumberLenghtValid = false
    @Published var isConfirmationCodeValid = false
    @Published var isConfirmationCodeLenghtValid = false
    @Published var isConfirmationCodeTrue = false
    
    
    
    
    var isRegFormValid: Bool {
            return isLoginLengthValid &&
                   isPasswordLengthValid &&
                   isPasswordCapitalLetter &&
                   isPasswordConfirmValid
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

    init(stateManager: RobotManager) {
        self.stateManager = stateManager
        
        $userLogin
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
                return password.count == 12
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
    
    func saveRegistrationData(userLogin: String, password: String) {
        print("saveRegistrationData")
        print("userlogin", userLogin)
        print("password", password)
        stateManager?.userLogin = userLogin
        stateManager?.isAuthenticated = true
    }
    

    
    func checkPhoneNumber(number: String) {
        print("checkPhoneNumber", number)
        stateManager?.isPhoneNumber = true // заглушка
        stateManager?.isAuthenticated = true
    }
    
    func checkConfirmationCode(code: String) {
        print("code", code)
        print(password, phoneNumber)
        if code == "3333" {
            print("Sucess")
            isConfirmationCodeTrue = true
        } else {
            print("не правильный код")
        }
    }
    
    
    
    
}

