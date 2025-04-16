//
//  UserRegistrationView.swift
//  CyberPilot
//
//  Created by Aleksandr Chumakov on 9/04/25.
//
import SwiftUI


struct UserRegistarationView: View {
    
    @ObservedObject var stateManager: RobotManager
    @ObservedObject var userRegistrationManager: UserRegistrationManager
    
    @State private var registrationStatus: String = ""
    
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Создать аккаунт")
                    .font(.system(.largeTitle, design: .rounded))
                    .bold()
                    .padding(.bottom, 30)
                
                FormField(fieldName: "Логин", fieldValue: $userRegistrationManager.userLogin)
                RequirementText(
                    iconColor: userRegistrationManager.isLoginLengthValid ? Color.secondary
                    : Color(red: 220/255, green: 220/255, blue: 220/255),
                    text: "Минимум 4 символа",
                    isStrikeThrough: userRegistrationManager.isLoginLengthValid
                )
                .padding()
                
                FormField(fieldName: "Пароль", fieldValue: $userRegistrationManager.password, isSecure: true)
                VStack {
                    RequirementText(
                        iconName: "lock.open",
                        iconColor: userRegistrationManager.isPasswordLengthValid ? Color.secondary : Color(red: 220/255, green: 220/255, blue: 220/255),
                        text: "Минимум 8 символов",
                        isStrikeThrough: userRegistrationManager.isPasswordLengthValid
                    )
                    RequirementText(
                        iconName: "lock.open",
                        iconColor: userRegistrationManager.isPasswordCapitalLetter ? Color.secondary : Color(red: 220/255, green: 220/255, blue: 220/255),
                        text: "Один символ с большой буквы",
                        isStrikeThrough: userRegistrationManager.isPasswordCapitalLetter
                    )
                }
                .padding()
                
                FormField(fieldName: "Подтвердите пароль", fieldValue: $userRegistrationManager.passwordConfirm, isSecure: true)
                RequirementText(
                    iconName: "lock.open",
                    iconColor: userRegistrationManager.isPasswordConfirmValid ? Color.secondary : Color(red: 220/255, green: 220/255, blue: 220/255),
                    text: "Пароль должен совпадать с введенным ранее",
                    isStrikeThrough: userRegistrationManager.isPasswordConfirmValid)
                .padding()
                .padding(.bottom, 50)
                
                
                Button(action: {
                    Task {
                        do {
                            try await userRegistrationManager.registerUser(username: userRegistrationManager.userLogin, password: userRegistrationManager.password)
                        } catch {
                            print("Ошибка регистрации: \(error.localizedDescription)")
                        }
                    }
                }
            )
                                                                                    {
                    Text("Зарегистрироваться")
                        .font(.system(.body, design: .rounded))
                        .foregroundColor(.white)
                        .bold()
                        .padding()
                        .frame(minWidth: 0, maxWidth: .infinity)
                        .background(LinearGradient(gradient: Gradient(colors: [Color(red: 34/255, green: 177/255, blue: 76/255), Color(red: 34/255, green: 177/255, blue: 76/255)]), startPoint: .leading, endPoint: .trailing))
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

}
