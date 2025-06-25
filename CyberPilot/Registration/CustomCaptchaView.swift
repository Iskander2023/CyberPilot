//
//  CaptchaView.swift
//  CyberPilot
//
//  Created by Aleksandr Chumakov on 7/04/25.
//
import SwiftUI


struct CustomCaptchaView: View {
    @State private var captchaText = ""
    @State private var userInput = ""
    @State private var attempts = 0
    @State private var isButtonDisabled = false
    @State private var remainingTime = 30

    var onCaptchaStep: (() -> Void)?

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 20) {
            Text(AppConfig.Strings.inputCaptchaText)
                .font(.headline)

            Text(captchaText)
                .font(.system(size: 24, weight: .bold, design: .monospaced))
                .padding(10)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(5)
                .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color.gray, lineWidth: 1))

            TextField(AppConfig.Strings.inputCaptcha, text: $userInput)
                .textFieldStyle(.roundedBorder)
                .autocapitalization(.allCharacters)
                .disableAutocorrection(true)

            Button(action: verifyCaptcha) {
                if isButtonDisabled {
                    Text("\(AppConfig.Strings.repeatIn) \(remainingTime)")
                } else {
                    Text(AppConfig.Strings.checkCaptcha)
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(isButtonDisabled)

            Button(AppConfig.Strings.updateCaptcha) {
                generateNewCaptcha()
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .onAppear {
            generateNewCaptcha()
        }
        .onReceive(timer) { _ in
            if remainingTime > 0 {
                remainingTime -= 1
            } else {
                isButtonDisabled = false
            }
        }
    }

    private func verifyCaptcha() {
        if userInput.uppercased() == captchaText {
            onCaptchaStep?()
        } else {
            attempts += 1
            generateNewCaptcha()

            if attempts >= 3 {
                isButtonDisabled = true
                remainingTime = 30
            }
        }
    }

    private func generateNewCaptcha() {
        captchaText = String((0..<4).map { _ in AppConfig.Strings.charactersForCaptcha.randomElement()! })
        userInput = ""
    }
}

