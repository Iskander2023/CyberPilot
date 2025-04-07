//
//  BindingView.swift
//  Robot_Controller
//
//  Created by Admin on 4/04/25.
//
import SwiftUI


struct PhoneView: View {
    @ObservedObject var stateManager: RobotManager
    @StateObject private var registrationManager: RegistrationManager
    @State private var showCaptcha = false
    @State private var isCaptchaVerified = false
    
    
    init(stateManager: RobotManager) {
        self.stateManager = stateManager
        self._registrationManager = StateObject(wrappedValue: RegistrationManager(stateManager: stateManager))
    }
    
    
    var body: some View {
        VStack {
            Text("Введите номер телефона")
                .font(.system(.largeTitle, design: .rounded))
                .bold()
                .padding(.bottom, 30)
            
            VStack {
                FormField(fieldName: "Номер +7", fieldValue: $registrationManager.phoneNumber)
                
                RequirementText(
                    iconName: "lock.open",
                    iconColor: registrationManager.isPhoneNumberValid ? Color.secondary : Color(red: 220/255, green: 220/255, blue: 220/255),
                    text: "только цифры",
                    isStrikeThrough: registrationManager.isPhoneNumberValid
                )
                
                RequirementText(
                    iconName: "lock.open",
                    iconColor: registrationManager.isPhoneNumberLenghtValid ? Color.secondary : Color(red: 220/255, green: 220/255, blue: 220/255),
                    text: "10",
                    isStrikeThrough: registrationManager.isPhoneNumberLenghtValid
                )
            }
            .padding()
            .padding(.bottom, 50)
            
            Button(action: {
                // Показываем капчу, если номер валиден
                if registrationManager.isPhoneNumberFormValid {
                    showCaptcha = true
                }
            }) {
                Text("Отправить")
                    .font(.system(.body, design: .rounded))
                    .foregroundColor(.white)
                    .bold()
                    .padding()
                    .frame(minWidth: 0, maxWidth: .infinity)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(red: 34/255, green: 177/255, blue: 76/255),
                                Color(red: 34/255, green: 177/255, blue: 76/255)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(10)
                    .padding(.horizontal)
            }
            .disabled(!registrationManager.isPhoneNumberFormValid)
            .opacity(registrationManager.isPhoneNumberFormValid ? 1.0 : 0.5)
        }
        .sheet(isPresented: $showCaptcha) {
            VStack {
                CustomCaptchaView(isVerified: $isCaptchaVerified)
                
                if isCaptchaVerified {
                    Button("Подтвердить отправку") {
                        showCaptcha = false
                        registrationManager.checkPhoneNumber(number: registrationManager.phoneNumber)
                    }
                    .padding()
                }
            }
            .padding()
        }
    }
}
