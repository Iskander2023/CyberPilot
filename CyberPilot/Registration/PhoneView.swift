//
//  BindingView.swift
//  Robot_Controller
//
//  Created by Aleksandr Chumakov on 4/04/25.
//
import SwiftUI


struct PhoneView: View {
    @ObservedObject var userRegistrationManager: UserRegistrationManager
    var onPhoneStep: () -> Void
    var body: some View {
        VStack {
            Text(AppConfig.Strings.inputPhoneNumber)
                .font(.system(.largeTitle, design: .rounded))
                .bold()
                .padding(.bottom, 30)
            
            VStack {
                FormField(fieldName: AppConfig.Strings.phoneNumberPrefix, fieldValue: $userRegistrationManager.phoneNumber)
                
                RequirementText(
                    iconName: AppConfig.Strings.iconName,
                    iconColor: userRegistrationManager.isPhoneNumberValid ? Color.secondary : AppConfig.Colors.inactiveGray,
                    text: AppConfig.Strings.onlyNumbers,
                    isStrikeThrough: userRegistrationManager.isPhoneNumberValid
                )
                
                RequirementText(
                    iconName: AppConfig.Strings.iconName,
                    iconColor: userRegistrationManager.isPhoneNumberLenghtValid ? Color.secondary : AppConfig.Colors.inactiveGray,
                    text: AppConfig.Strings.phoneNumbersCount,
                    isStrikeThrough: userRegistrationManager.isPhoneNumberLenghtValid
                )
            }
            .padding()
            .padding(.bottom, 50)
            
            Button(action: {
                if userRegistrationManager.isPhoneNumberFormValid {
                    onPhoneStep()
                }
            }) {
                Text(AppConfig.Strings.sendPhoneNumber)
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
            .disabled(!userRegistrationManager.isPhoneNumberFormValid)
            .opacity(userRegistrationManager.isPhoneNumberFormValid ? 1.0 : 0.5)
        }
            
    }
}
