//
//  LoginView.swift
//  Robot_Controller
//
//  Created by Aleksandr Chumakov on 3/04/25.
//

import SwiftUI

struct LoginView: View {
    @ObservedObject var authService: AuthService
    @StateObject private var loginManager: LoginManager
    @StateObject var registrationManager: UserRegistrationManager
    @State private var isLoginSuccessful = false
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    
    
    init(authService: AuthService) {
        self.authService = authService
        _loginManager = StateObject(wrappedValue: LoginManager(authService: authService))
        _registrationManager = StateObject(wrappedValue: UserRegistrationManager(stateManager: authService))
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
                                _ = try await loginManager.login(email: loginManager.email, password: loginManager.password)
                                isLoginSuccessful = true
                            } catch {
                                //errorMessage = error.localizedDescription
                                errorMessage = "Не удалось войти. Проверьте данные и попробуйте снова."
                               //"The operation couldn’t be completed. (NSURLErrorDomain error -1011.)"
                                showErrorAlert = true
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
                    
                    NavigationLink(destination: RegistrationFlowView(stateManager: authService, userRegistrationManager: registrationManager)) {
                        Text("Зарегистрироваться")
                            .font(.system(.body, design: .rounded))
                            .bold()
                            .foregroundColor(Color(red: 34/255, green: 177/255, blue: 76/255))
                    }
                }.padding(.top, 50)
                
            }
            .alert("Ошибка входа", isPresented: $showErrorAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
}
