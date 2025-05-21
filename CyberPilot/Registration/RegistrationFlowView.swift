//
//  RegView.swift
//  Robot_Controller
//
//  Created by Aleksandr Chumakov on 2/04/25.
//
import SwiftUI


struct RegistrationFlowView: View {
    @ObservedObject var stateManager: AuthService
    @ObservedObject var userRegistrationManager: UserRegistrationManager
    @State private var currentStep: RegistrationStep = .phoneInput
    
    @Environment(\.dismiss) private var dismiss
    
    let logger = CustomLogger(logLevel: .info, includeMetadata: false)
    
    enum RegistrationStep {
        case phoneInput
        case captcha
        case confirmationCode
        case userRegistrationInput
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
                case .userRegistrationInput:
                    userRegistrationView
                        .transition(.move(edge: .trailing))
                    }
        }
        .animation(.easeInOut(duration: 0.4), value: currentStep)
        .padding()
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(leading: Button("< Назад") {
            goToPreviousStep()
            }
        )
    }

    
    private var phoneView: some View {
        PhoneView(
            userRegistrationManager: userRegistrationManager,
            onPhoneStep: {
                withAnimation {
                    currentStep = .captcha
                }
            }
        )
    }

    
    private var captchaView: some View {
        CustomCaptchaView(
            onCaptchaStep: {
                //отправка кода
                let code = String(Int.random(in: 1000...9999))
                self.logger.info("code: \(code)")
                userRegistrationManager.generatedCode = code
                    // 2. Отправка SMS
                userRegistrationManager.sendVerificationCode(
                        to: userRegistrationManager.phoneNumber,
                        code: code
                   )
                withAnimation {
                    currentStep = .confirmationCode
                }
            }
        )
    }


    private var confirmationCodeView: some View {
        ConfirmationCodeView(
            stateManager: stateManager,
            userRegistrationManager: userRegistrationManager,
            onCodeStep: {
                withAnimation {
                    currentStep = .userRegistrationInput
                }
            }
        )
    }
    
    
    private var userRegistrationView: some View {
        UserRegistarationView(
            stateManager: stateManager,
            userRegistrationManager: userRegistrationManager
        )
    }
        
    private func goToPreviousStep() {
        withAnimation {
            switch currentStep {
                
            case .captcha:
                currentStep = .phoneInput
            case .confirmationCode:
                currentStep = .captcha
            case .phoneInput:
                dismiss()
            case .userRegistrationInput:
                currentStep = .confirmationCode
                
            }
        }
    }
}




