//
//  UserRegistrationView.swift
//  CyberPilot
//
//  Created by Aleksandr Chumakov on 9/04/25.
//
import SwiftUI


struct UserRegistrationView: View {
    
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var userRegistrationManager: UserRegistrationManager
    
    @State private var registrationStatus: String = ""
    
    
    var body: some View {
            VStack {
                Text(AppConfig.Strings.registrationTitle)
                    .font(.system(.largeTitle, design: .rounded))
                    .bold()
                    .padding(.bottom, 30)
                
                FormField(fieldName: AppConfig.Strings.emailRus, fieldValue: $userRegistrationManager.email)
                RequirementText(
                    iconName: AppConfig.Strings.iconName,
                    iconColor: userRegistrationManager.isMailValid ? Color.secondary
                    :AppConfig.Colors.inactiveGray,
                    text: AppConfig.Strings.EmailEng,
                    isStrikeThrough: userRegistrationManager.isMailValid
                )
                .padding()
                
                FormField(fieldName: AppConfig.Strings.loginRus, fieldValue: $userRegistrationManager.userName)
                RequirementText(
                    iconName: AppConfig.Strings.iconName,
                    iconColor: userRegistrationManager.isLoginLengthValid ? Color.secondary
                    : AppConfig.Colors.inactiveGray,
                    text: AppConfig.Strings.min4Simbols,
                    isStrikeThrough: userRegistrationManager.isLoginLengthValid
                )
                .padding()
                
                FormField(fieldName: AppConfig.Strings.passwordRus, fieldValue: $userRegistrationManager.password, isSecure: true)
                VStack {
                    RequirementText(
                        iconName: AppConfig.Strings.iconName,
                        iconColor: userRegistrationManager.isPasswordLengthValid ? Color.secondary : AppConfig.Colors.inactiveGray,
                        text: AppConfig.Strings.min8Simbols,
                        isStrikeThrough: userRegistrationManager.isPasswordLengthValid
                    )
                    RequirementText(
                        iconName: AppConfig.Strings.iconName,
                        iconColor: userRegistrationManager.isPasswordCapitalLetter ? Color.secondary : AppConfig.Colors.inactiveGray,
                        text: AppConfig.Strings.OneSymbolWithACapitalLetter,
                        isStrikeThrough: userRegistrationManager.isPasswordCapitalLetter
                    )
                }
                .padding()
                
                FormField(fieldName: AppConfig.Strings.confirmPassword, fieldValue: $userRegistrationManager.passwordConfirm, isSecure: true)
                RequirementText(
                    iconName: AppConfig.Strings.iconName,
                    iconColor: userRegistrationManager.isPasswordConfirmValid ? Color.secondary : AppConfig.Colors.inactiveGray,
                    text: AppConfig.Strings.passwordMatch,
                    isStrikeThrough: userRegistrationManager.isPasswordConfirmValid)
                .padding()
                .padding(.bottom, 50)
                
                if !registrationStatus.isEmpty {
                    Text(registrationStatus)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding()
                }
                
                Button(action: {
                    Task {
                        do {
                            try await userRegistrationManager.registerUser(email: userRegistrationManager.email, 
                                                                           username: userRegistrationManager.userName,
                                                                           password: userRegistrationManager.password
                                                                           )
                                                                           registrationStatus = AppConfig.Strings.registrationStatusTrue
                                                                           userRegistrationManager.clearFields()
                        } catch {
                            registrationStatus = "\(AppConfig.Strings.registrationStatusFalse) \(error.localizedDescription)"
                            print("\(AppConfig.Strings.registrationStatusFalse) \(error.localizedDescription)")
                        }
                    }
                }
            )
                {
                    Text(AppConfig.Strings.registerButtonTitle)
                        .font(.system(.body, design: .rounded))
                        .foregroundColor(.white)
                        .bold()
                        .padding()
                        .frame(minWidth: 0, maxWidth: .infinity)
                        .background(LinearGradient(gradient: Gradient(colors: [AppConfig.Colors.primaryGreen,
                                                                               AppConfig.Colors.primaryGreen]),
                                                   startPoint: .leading, endPoint: .trailing))
                        .cornerRadius(10)
                        .padding(.horizontal)
                    
                }
                .disabled(!userRegistrationManager.isRegFormValid) // Делаем кнопку неактивной, если форма невалидна
                .opacity(userRegistrationManager.isRegFormValid ? 1.0 : 0.5)
                
                Spacer()
            }
            .padding()
        }
    }

