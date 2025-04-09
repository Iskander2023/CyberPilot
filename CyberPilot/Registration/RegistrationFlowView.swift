//
//  RegView.swift
//  Robot_Controller
//
//  Created by Admin on 2/04/25.
//
import SwiftUI


struct RegistrationFlowView: View {
    @ObservedObject var stateManager: RobotManager
    @ObservedObject var registrationManager: RegistrationManager
    
    @State private var currentStep: RegistrationStep = .phoneInput
    @State private var isCaptchaVerified: Bool = false
    
    @Environment(\.dismiss) private var dismiss
    
    
    enum RegistrationStep {
        case phoneInput
        case captcha
        case confirmationCode
    }
    
    var body: some View {
        ZStack {
            switch currentStep {
                case .phoneInput:
                    phoneView
                        .transition(.move(edge: .leading))
                case .captcha:
                    captchaView
                        .transition(.move(edge: .trailing))
                case .confirmationCode:
                    confirmationCodeView
                        .transition(.move(edge: .trailing))
                }
        }
        .animation(.easeInOut(duration: 0.4), value: currentStep)
        .padding()
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(leading: Button("< Назад") {
            goToPreviousStep()
        })
    }

    
    private var phoneView: some View {
        PhoneView(
            stateManager: stateManager,
            registrationManager: registrationManager,
            onNextStep: {
                withAnimation {
                    currentStep = .captcha
                }
            }
        )
    }

    
    private var captchaView: some View {
        CustomCaptchaView(
            isVerified: $isCaptchaVerified,
            onSuccess: {
                withAnimation {
                    currentStep = .confirmationCode
                }
            }
        )
    }


    private var confirmationCodeView: some View {
            ConfirmationCodeView(
                stateManager: stateManager,
                registrationManager: registrationManager
            )}

        
    private func goToPreviousStep() {
        withAnimation {
            switch currentStep {
            case .captcha:
                currentStep = .phoneInput
            case .confirmationCode:
                currentStep = .captcha
            case .phoneInput:
                dismiss()
            }
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
