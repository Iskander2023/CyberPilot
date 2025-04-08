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

    @State private var currentStep: RegistrationStep = .phoneInput
    @State private var isCaptchaVerified: Bool = false
    

    enum RegistrationStep {
        case phoneInput
        case captcha
        case confirmationCode
    }

    init(stateManager: RobotManager) {
        self.stateManager = stateManager
        self._registrationManager = StateObject(wrappedValue: RegistrationManager(stateManager: stateManager))
    }

    var body: some View {
        VStack {
            switch currentStep {
            case .phoneInput:
                            PhoneView(stateManager: stateManager, registrationManager: registrationManager, onNextStep: {
                                currentStep = .captcha
                            })
            case .captcha:
                captchaView
            case .confirmationCode:
                confirmationCodeView
            }
        }
        .animation(.easeInOut, value: currentStep)
        .transition(.slide)
    }

    private var captchaView: some View {
        CustomCaptchaView(isVerified: $isCaptchaVerified) {
            currentStep = .confirmationCode
        }
    }

    private var confirmationCodeView: some View {
        ConfirmationCodeView(stateManager: stateManager, registrationManager: registrationManager)
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
