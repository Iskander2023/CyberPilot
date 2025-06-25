//
//  ConfirmationCodeView.swift
//  CyberPilot
//
//  Created by Aleksandr Chumakov on 7/04/25.
//
import SwiftUI



struct ConfirmationCodeView: View {
    
    @ObservedObject var stateManager: AuthService
    @ObservedObject var userRegistrationManager: UserRegistrationManager
    @EnvironmentObject var alertManager: AlertManager
    
    var onCodeStep: () -> Void
    
    var body: some View {
        VStack {
            Text(AppConfig.Strings.enterReciverCode)
                .font(.system(.largeTitle, design: .rounded))
                .bold()
                .padding(.bottom, 30)
            
            VStack {
                FormField(fieldName: AppConfig.Strings.code, fieldValue: $userRegistrationManager.confirmationCode)
                
                RequirementText(
                    iconName: AppConfig.Strings.iconName,
                    iconColor: userRegistrationManager.isConfirmationCodeValid ? Color.secondary : AppConfig.Colors.inactiveGray,
                    text: AppConfig.Strings.onlyNumbers,
                    isStrikeThrough: userRegistrationManager.isConfirmationCodeValid
                )
                
                RequirementText(
                    iconName: AppConfig.Strings.iconName,
                    iconColor: userRegistrationManager.isConfirmationCodeLenghtValid ? Color.secondary : AppConfig.Colors.inactiveGray,
                    text: AppConfig.Strings.codeLength,
                    isStrikeThrough: userRegistrationManager.isConfirmationCodeLenghtValid
                )
            }
            .padding()
            .padding(.bottom, 50)
            
            Button(action: {
                userRegistrationManager.checkConfirmationCode(code: userRegistrationManager.confirmationCode)
                
                if userRegistrationManager.isConfirmationCodeTrue && userRegistrationManager.isPhoneNumberFormValid {
                    onCodeStep()
                } else {
                    alertManager.showAlert(title: AppConfig.Strings.errorMessage, message: AppConfig.Strings.incorrectCodeMessage)
                }
            }) {
                Text(AppConfig.Strings.confirm)
                    .font(.system(.body, design: .rounded))
                    .foregroundColor(.white)
                    .bold()
                    .padding()
                    .frame(minWidth: 0, maxWidth: .infinity)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                AppConfig.Colors.primaryGreen,
                                AppConfig.Colors.primaryGreen
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
        .globalAlert()
    }
}
