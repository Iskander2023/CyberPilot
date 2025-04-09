//
//  LoginView.swift
//  Robot_Controller
//
//  Created by Aleksandr Chumakov on 3/04/25.
//

import SwiftUI

struct LoginView: View {
    
    @ObservedObject var stateManager: RobotManager
    @StateObject private var registrationManager: RegistrationManager
    
    init(stateManager: RobotManager) {
        self.stateManager = stateManager
        self._registrationManager = StateObject(wrappedValue: RegistrationManager(stateManager: stateManager))
    }
    
    
    var body: some View {
        VStack {
            Text("Введите данные")
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
            RequirementText(
                iconName: "lock.open",
                iconColor: registrationManager.isPasswordLengthValid ? Color.secondary : Color(red: 220/255, green: 220/255, blue: 220/255),
                text: "Минимум 8 символов",
                isStrikeThrough: registrationManager.isPasswordLengthValid
            )
            .padding()
            
            HStack {
                Button(action: {registrationManager.saveLoginData(
                    userLogin:registrationManager.userLogin,
                    password:registrationManager.password)
                }) {
                    Text("Вход")
                        .font(.system(.body, design: .rounded))
                        .bold()
                        .foregroundColor(Color(red: 34/255, green: 177/255, blue: 76/255))
                }
            }
            .padding(.top, 50)
            .disabled(!registrationManager.isLoginFormValid)
            .opacity(registrationManager.isLoginFormValid ? 1.0 : 0.5)
            
            
            HStack {
                Text("Нет аккаунта?")
                    .font(.system(.body, design: .rounded))
                    .bold()

                NavigationLink(destination: RegistrationFlowView(stateManager: stateManager, registrationManager: registrationManager)) {
                    Text("Зарегистрироваться")
                        .font(.system(.body, design: .rounded))
                        .bold()
                        .foregroundColor(Color(red: 34/255, green: 177/255, blue: 76/255))
                }
            }.padding(.top, 50)
        }
    }
}
