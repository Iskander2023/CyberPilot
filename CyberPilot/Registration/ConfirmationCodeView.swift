//
//  ConfirmationCodeView.swift
//  CyberPilot
//
//  Created by Admin on 7/04/25.
//
import SwiftUI


struct ConfirmationCodeView: View {
    
    @ObservedObject var stateManager: RobotManager
    @ObservedObject var userRegistrationManager: UserRegistrationManager
    
    var onCodeStep: () -> Void
    
    var body: some View {
        VStack {
            Text("Введите полученый код")
                .font(.system(.largeTitle, design: .rounded))
                .bold()
                .padding(.bottom, 30)
            
            VStack {
                FormField(fieldName: "Код", fieldValue: $userRegistrationManager.confirmationCode)
                
                RequirementText(
                    iconName: "lock.open",
                    iconColor: userRegistrationManager.isConfirmationCodeValid ? Color.secondary : Color(red: 220/255, green: 220/255, blue: 220/255),
                    text: "только цифры",
                    isStrikeThrough: userRegistrationManager.isConfirmationCodeValid
                )
                
                RequirementText(
                    iconName: "lock.open",
                    iconColor: userRegistrationManager.isConfirmationCodeLenghtValid ? Color.secondary : Color(red: 220/255, green: 220/255, blue: 220/255),
                    text: "4",
                    isStrikeThrough: userRegistrationManager.isConfirmationCodeLenghtValid
                )
            }
            .padding()
            .padding(.bottom, 50)
            
            Button(action: {
                userRegistrationManager.checkConfirmationCode(code: userRegistrationManager.confirmationCode)
                
                if userRegistrationManager.isConfirmationCodeTrue && userRegistrationManager.isPhoneNumberFormValid {
                    onCodeStep()
                }
            }) {
                Text("Подтвердить")
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
            .disabled(!userRegistrationManager.isCodeNumberFormValid)
            .opacity(userRegistrationManager.isCodeNumberFormValid ? 1.0 : 0.5)
        }
    }
}
