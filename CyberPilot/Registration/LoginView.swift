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
                Text(AppConfig.Strings.enterData)
                    .font(.system(.largeTitle, design: .rounded))
                    .bold()
                    .padding(.bottom, 30)
                
                FormField(fieldName: AppConfig.Strings.loginRus, fieldValue: $loginManager.email)
                RequirementText(
                    iconName: AppConfig.Strings.iconName,
                    iconColor: loginManager.isMailValid ? Color.secondary
                    : AppConfig.Colors.inactiveGray,
                    text: AppConfig.Strings.emailRus,
                    isStrikeThrough: loginManager.isMailValid
                )
                .padding()
                
                FormField(fieldName: AppConfig.Strings.passwordRus, fieldValue: $loginManager.password, isSecure: true)
                RequirementText(
                    iconName: AppConfig.Strings.iconName,
                    iconColor: loginManager.isPasswordLengthValid ? Color.secondary : AppConfig.Colors.inactiveGray,
                    text: AppConfig.Strings.min8Simbols,
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
                                errorMessage = AppConfig.Strings.errorLoginMessage
                               //"The operation couldn’t be completed. (NSURLErrorDomain error -1011.)"
                                showErrorAlert = true
                            }
                        }
                    }) {
                        Text(AppConfig.Strings.loginEntry)
                            .font(.system(.body, design: .rounded))
                            .bold()
                            .foregroundColor(AppConfig.Colors.primaryGreen)
                    }
                }
                .padding(.top, 50)
                .disabled(!loginManager.isLoginFormValid)
                .opacity(loginManager.isLoginFormValid ? 1.0 : 0.5)
                
                
                HStack {
                    Text(AppConfig.Strings.dontHaveAccount)
                        .font(.system(.body, design: .rounded))
                        .bold()
                    
                    NavigationLink(destination: RegistrationFlowView(stateManager: authService, userRegistrationManager: registrationManager)) {
                        Text(AppConfig.Strings.registerButtonTitle)
                            .font(.system(.body, design: .rounded))
                            .bold()
                            .foregroundColor(AppConfig.Colors.primaryGreen)
                    }
                }.padding(.top, 50)
                
            }
            .alert(AppConfig.Strings.loginError, isPresented: $showErrorAlert) {
                Button(AppConfig.Strings.buttonOk, role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
}
