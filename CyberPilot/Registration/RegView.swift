//
//  RegView.swift
//  Robot_Controller
//
//  Created by Admin on 2/04/25.
//

import SwiftUI

struct RegView: View {
    @ObservedObject var stateManager: RobotManager
    @StateObject private var registrationManager: RegistrationManager
    
    init(stateManager: RobotManager) {
            self.stateManager = stateManager
            self._registrationManager = StateObject(wrappedValue: RegistrationManager(stateManager: stateManager))
        }
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Создать аккаунт")
                    .font(.system(.largeTitle, design: .rounded))
                    .bold()
                    .padding(.bottom, 30)
                
                FormField(fieldName: "Логин", fieldValue: $registrationManager.userLogin)
                RequirementText(
                    iconColor: registrationManager.isLoginLengthValid ? Color.secondary
                    : Color(red: 220/255, green: 220/255, blue: 220/255),
                    text: "Минимум 4 символа",
                    isStrikeThrough: registrationManager.isLoginLengthValid
                )
                .padding()
                
                FormField(fieldName: "Пароль", fieldValue: $registrationManager.password, isSecure: true)
                VStack {
                    RequirementText(
                        iconName: "lock.open",
                        iconColor: registrationManager.isPasswordLengthValid ? Color.secondary : Color(red: 220/255, green: 220/255, blue: 220/255),
                        text: "Минимум 8 символов",
                        isStrikeThrough: registrationManager.isPasswordLengthValid
                    )
                    RequirementText(
                        iconName: "lock.open",
                        iconColor: registrationManager.isPasswordCapitalLetter ? Color.secondary : Color(red: 220/255, green: 220/255, blue: 220/255),
                        text: "Один символ с большой буквы",
                        isStrikeThrough: registrationManager.isPasswordCapitalLetter
                    )
                }
                .padding()
                
                FormField(fieldName: "Подтвердите пароль", fieldValue: $registrationManager.passwordConfirm, isSecure: true)
                RequirementText(
                    iconName: "lock.open",
                    iconColor: registrationManager.isPasswordConfirmValid ? Color.secondary : Color(red: 220/255, green: 220/255, blue: 220/255),
                    text: "Пароль должен совпадать с введенным ранее",
                    isStrikeThrough: registrationManager.isPasswordConfirmValid)
                .padding()
                .padding(.bottom, 50)
                
                
                Button(action: {registrationManager.saveRegistrationData(
                    userLogin:registrationManager.userLogin,
                    password:registrationManager.password)
                }) {
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
                .disabled(!registrationManager.isRegFormValid) // Делаем кнопку неактивной, если форма невалидна
                .opacity(registrationManager.isRegFormValid ? 1.0 : 0.5)
                
//                HStack {
//                    Text("Уже есть аккаунт?")
//                        .font(.system(.body, design: .rounded))
//                        .bold()
//
//                    NavigationLink(destination: LoginView(stateManager: stateManager)) {
//                        Text("Войти")
//                            .font(.system(.body, design: .rounded))
//                            .bold()
//                            .foregroundColor(Color(red: 34/255, green: 177/255, blue: 76/255))
//                    }
//                }.padding(.top, 50)
                
                Spacer()
            }
            .padding()
        }
    }

}


struct FormField: View {
    var fieldName = ""
    @Binding var fieldValue: String
    
    var isSecure = false
    
    var body: some View {
        
        VStack {
            if isSecure {
                SecureField(fieldName, text: $fieldValue)
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .padding(.horizontal)
                
            } else {
                TextField(fieldName, text: $fieldValue)
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .padding(.horizontal)
            }

            Divider()
                .frame(height: 1)
                .background(Color(red: 220/255, green: 220/255, blue: 220/255))
                .padding(.horizontal)
            
        }
    }
}

struct RequirementText: View {
    
    var iconName = "xmark.square"
    var iconColor = Color(red: 220/255, green: 220/255, blue: 220/255)
    
    var text = ""
    var isStrikeThrough = false
    
    var body: some View {
        HStack {
            Image(systemName: iconName)
                .foregroundColor(iconColor)
            Text(text)
                .font(.system(.body, design: .rounded))
                .foregroundColor(.secondary)
                .strikethrough(isStrikeThrough)
            Spacer()
        }
    }
}
