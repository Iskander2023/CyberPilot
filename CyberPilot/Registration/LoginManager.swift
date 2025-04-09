//
//  LoginManager.swift
//  CyberPilot
//
//  Created by Admin on 9/04/25.
//
import SwiftUI
import Combine


class LoginManager: ObservableObject {
    
    private weak var stateManager: RobotManager?
    
    @Published var userLogin = ""
    @Published var password = ""
    
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
    }
    
    func login(stateManager: RobotManager) {
        print("Логин: \(userLogin), Пароль: \(password)")
        stateManager.userLogin = userLogin
        stateManager.isAuthenticated = true
    }
    
    func saveLoginData(userLogin: String, password: String) {
        print("saveLoginData")
        print("userlogin", userLogin)
        print("password", password)
        stateManager?.userLogin = userLogin
        stateManager?.isAuthenticated = true
    }
}

