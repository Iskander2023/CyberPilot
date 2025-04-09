//
//  CaptchaView.swift
//  CyberPilot
//
//  Created by Aleksandr Chumakov on 7/04/25.
//
import SwiftUI


struct CustomCaptchaView: View {
    @Binding var isVerified: Bool
    @State private var captchaText = ""
    @State private var userInput = ""
    @State private var attempts = 0
    @State private var isButtonDisabled = false
    @State private var remainingTime = 30
    
    var onSuccess: (() -> Void)?
    
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    private let characters = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
    
    
    var body: some View {
        VStack(spacing: 20) {
            if !isVerified {
                Text("Введите текст ниже:")
                    .font(.headline)
                
                Text(captchaText)
                    .font(.system(size: 24, weight: .bold, design: .monospaced))
                    .padding(10)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(5)
                    .overlay(
                        RoundedRectangle(cornerRadius: 5)
                            .stroke(Color.gray, lineWidth: 1)
                    )
                
                TextField("Введите капчу", text: $userInput)
                    .textFieldStyle(.roundedBorder)
                    .autocapitalization(.allCharacters)
                    .disableAutocorrection(true)
                
                Button(action: verifyCaptcha) {
                    if isButtonDisabled {
                        Text("Повторить через \(remainingTime) сек")
                    } else {
                        Text("Проверить")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isButtonDisabled || isVerified)
                
                Button("Обновить капчу") {
                    generateNewCaptcha()
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .onAppear {
            withAnimation {
                isVerified = false // Принудительный сброс
                generateNewCaptcha()
            }
        }
        .onReceive(timer) { _ in
            if remainingTime > 0 {
                remainingTime -= 1
            } else {
                isButtonDisabled = false
            }
        }
        .onChange(of: isVerified) {
            if isVerified {
                onSuccess?()
            }
        }
    }
    
    private func resetState() {
        isVerified = false
        captchaText = ""
        userInput = ""
        attempts = 0
        isButtonDisabled = false
        remainingTime = 30
        generateNewCaptcha()
    }
    
    
    private func verifyCaptcha() {
        if userInput == captchaText {
            isVerified = true
            attempts = 0
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
        captchaText = String((0..<6).map { _ in characters.randomElement()! })
        userInput = ""
    }
}
