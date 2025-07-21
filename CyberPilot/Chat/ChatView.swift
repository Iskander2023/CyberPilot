//
//  ChatView.swift
//  CyberPilot
//
//  Created by Aleksandr Chumakov on 16/07/25.
//
import Foundation
import SwiftUI



struct ChatView: View {
    @EnvironmentObject private var chatService: ChatService
    @State private var usermessage: String = ""
    @State private var messages: [String] = []
    @State private var showDocumentPicker = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Основная область сообщений
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(messages.indices, id: \.self) { index in
                            Text(messages[index])
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                                .padding(.horizontal, 8)
                                .id(index)
                        }
                    }
                    .padding(.vertical, 8)
                }
                .background(Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
                .padding(.horizontal, 8)
                .onChange(of: messages) { _, newMessages in
                    if !newMessages.isEmpty {
                        withAnimation {
                            proxy.scrollTo(newMessages.count - 1, anchor: .bottom)
                        }
                    }
                }
            }
            .frame(maxHeight: .infinity)
            
            // Панель ввода с четкими границами
            HStack(spacing: 12) {
                // Поле ввода с рамкой
                ZStack(alignment: .topLeading) {
                    TextEditor(text: $usermessage)
                        .frame(minHeight: 40, maxHeight: 100)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 8)
                        .scrollContentBackground(.hidden)
                        .background(Color.clear)
                    
                    if usermessage.isEmpty {
                        Text("Введите сообщение...")
                            .foregroundColor(.gray)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 12)
                            .allowsHitTesting(false)
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(Color.gray.opacity(0.3), lineWidth: 1)
                        .background(Color(.secondarySystemBackground).cornerRadius(10))
                )
                
                // Кнопка отправки
                Button(action: sendMessage) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(usermessage.trimmed.isEmpty ? .gray : .blue)
                }
                .disabled(usermessage.trimmed.isEmpty)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.systemBackground))
            .overlay(
                Divider().background(Color.gray.opacity(0.3)),
                alignment: .top
            )
        }
        .background(Color(.systemBackground))
    }
    
    private func sendMessage() {
        let trimmed = usermessage.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        let messageWithTime = "\(chatService.formattedDate(Date())) - \(trimmed)"
        messages.append(messageWithTime)
        chatService.sendMessageToRobot(message: trimmed)
        usermessage = ""
    }
}

extension String {
    var trimmed: String {
        self.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

