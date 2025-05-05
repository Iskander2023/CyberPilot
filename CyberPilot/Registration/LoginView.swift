//
//  LoginView.swift
//  Robot_Controller
//
//  Created by Aleksandr Chumakov on 3/04/25.
//

import SwiftUI

struct LoginView: View {
    @ObservedObject var stateManager: RobotManager
    @StateObject private var loginManager: LoginManager
    @StateObject var registrationManager: UserRegistrationManager
    @State private var isLoginSuccessful = false


    init(stateManager: RobotManager) {
        self.stateManager = stateManager
        _loginManager = StateObject(wrappedValue: LoginManager(stateManager: stateManager))
        _registrationManager = StateObject(wrappedValue: UserRegistrationManager(stateManager: stateManager))
    }

    
    var body: some View {
        ScrollView {
            VStack {
                Text("Введите данные")
                    .font(.system(.largeTitle, design: .rounded))
                    .bold()
                    .padding(.bottom, 30)
                
                FormField(fieldName: "Логин", fieldValue: $loginManager.email)
                RequirementText(
                    iconColor: loginManager.isMailValid ? Color.secondary
                    : Color(red: 220/255, green: 220/255, blue: 220/255),
                    text: "Минимум 4 символа",
                    isStrikeThrough: loginManager.isMailValid
                )
                .padding()
                
                FormField(fieldName: "Пароль", fieldValue: $loginManager.password, isSecure: true)
                RequirementText(
                    iconName: "lock.open",
                    iconColor: loginManager.isPasswordLengthValid ? Color.secondary : Color(red: 220/255, green: 220/255, blue: 220/255),
                    text: "Минимум 8 символов",
                    isStrikeThrough: loginManager.isPasswordLengthValid
                )
                .padding()
                
                HStack {
                    Button(action: {
                        Task {
                            do {
                                let token = try await loginManager.login(email: loginManager.email, password: loginManager.password)
                                isLoginSuccessful = true
                                print("Успешный вход")
                            } catch {
                                print("Ошибка входа: \(error.localizedDescription)")
                            }
                        }
                    }) {
                        Text("Вход")
                            .font(.system(.body, design: .rounded))
                            .bold()
                            .foregroundColor(Color(red: 34/255, green: 177/255, blue: 76/255))
                    }
                }
                .padding(.top, 50)
                .disabled(!loginManager.isLoginFormValid)
                .opacity(loginManager.isLoginFormValid ? 1.0 : 0.5)
                
                
                HStack {
                    Text("Нет аккаунта?")
                        .font(.system(.body, design: .rounded))
                        .bold()
                    
                    NavigationLink(destination: RegistrationFlowView(stateManager: stateManager, userRegistrationManager: registrationManager)) {
                        Text("Зарегистрироваться")
                            .font(.system(.body, design: .rounded))
                            .bold()
                            .foregroundColor(Color(red: 34/255, green: 177/255, blue: 76/255))
                    }
                }.padding(.top, 50)
                
            }
        }
    }
}
