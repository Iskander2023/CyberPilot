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
    
    private let characters = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
    
    var body: some View {
        VStack(spacing: 20) {
            if isVerified {
                Text("✅ Капча пройдена!")
                    .foregroundColor(.green)
            } else {
                // Показываем капчу и поле ввода
                Text("Введите текст ниже:")
                    .font(.headline)
                
                // Капча (текст + обводка для сложности)
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
                
                Button("Проверить") {
                    if userInput == captchaText {
                        isVerified = true
                    } else {
                        attempts += 1
                        generateNewCaptcha()
                        if attempts >= 3 {
                            // Можно добавить блокировку на время
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
                
                Button("Обновить капчу") {
                    generateNewCaptcha()
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .onAppear {
            generateNewCaptcha()
        }
    }
    
    private func generateNewCaptcha() {
        captchaText = String((0..<6).map { _ in characters.randomElement()! })
        userInput = ""
    }
}
