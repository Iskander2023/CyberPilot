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
    @EnvironmentObject private var socketController: SocketController
    @State private var usermessage: String = ""
    @State private var showDocumentPicker = false
    
    var body: some View {
        mainContainer
    }
    
    private var mainContainer: some View {
        VStack(spacing: 0) {
            headerSection
            messageScrollSection
            inputPanelSection
        }
        .background(Color(.systemBackground))
    }
    
    private var headerSection: some View {
        HStack {
            headerText
            connectionIndicator
        }
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }
    
    private var headerText: some View {
        Text("Чат с роботом: \(robotIdPrefix)…")
            .font(.headline)
            .padding(.leading, 16)
    }
    
    private var robotIdPrefix: String {
        String(socketController.selectedRobot?.robot_id.prefix(4) ?? "робот не подключен")
    }
    
    private var connectionIndicator: some View {
        Circle()
            .frame(width: AppConfig.ChatView.connectionIndicatorCircleWidth,
                   height: AppConfig.ChatView.connectionIndicatorCircleHeight)
            .foregroundColor(connectionColor)
    }
    
    private var connectionColor: Color {
        socketController.connectionManager.isConnected ?
            AppConfig.SocketView.connectionIndicatorConnectColor :
            AppConfig.SocketView.connectionIndicatorDisconnectColor
    }
    
    private var messageScrollSection: some View {
        ScrollViewReader { proxy in
            ScrollView {
                messageList
            }
            .scrollViewStyle
            .onChange(of: chatService.messages) {
                scrollToLastMessage(proxy: proxy)
            }
        }
        .frame(maxHeight: .infinity)
    }
    
    private var messageList: some View {
        LazyVStack(spacing: 8) {
            ForEach(chatService.messages) { message in
                ChatMessageRow(message: message, userName: chatService.authService.userLogin)
            }
        }
        .padding(.vertical, 8)
    }
    
    private func scrollToLastMessage(proxy: ScrollViewProxy) {
        guard let lastId = chatService.messages.last?.id else { return }
        withAnimation {
            proxy.scrollTo(lastId, anchor: .bottom)
        }
    }
    
    private var inputPanelSection: some View {
        HStack(spacing: 12) {
            messageInputField
            sendButton
        }
        .inputPanelStyle
    }
    
    private var messageInputField: some View {
        ZStack(alignment: .topLeading) {
            TextEditor(text: $usermessage)
                .textEditorStyle
            
            if usermessage.isEmpty {
                placeholderText
            }
        }
        .inputFieldBackground
    }
    
    private var placeholderText: some View {
        Text("Enter message...")
            .foregroundColor(.gray)
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .allowsHitTesting(false)
    }
    
    private var sendButton: some View {
        Button(action: sendMessage) {
            Image(systemName: "arrow.up.circle.fill")
                .font(.system(size: 32))
                .foregroundColor(sendButtonColor)
        }
        .disabled(usermessage.trimmed.isEmpty)
    }
    
    private var sendButtonColor: Color {
        usermessage.trimmed.isEmpty ? .gray : .blue
    }
    
    private func sendMessage() {
        let trimmed = usermessage.trimmed
        guard !trimmed.isEmpty else { return }

        let chatMessage = ChatMessage(
            sender: .user,
            text: trimmed,
            time: Date()
        )
        chatService.messages.append(chatMessage)
        chatService.sendMessageToRobot(message: trimmed)
        usermessage = ""
    }
}

// MARK: - View Modifiers
extension View {
    var scrollViewStyle: some View {
        self
            .background(AppConfig.ChatView.chatBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.5), lineWidth: 2)
            )
            .padding(.horizontal, 8)
    }
    
    var textEditorStyle: some View {
        self
            .frame(minHeight: 40, maxHeight: 100)
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
            .scrollContentBackground(.hidden)
            .background(Color.clear)
    }
    
    var inputFieldBackground: some View {
        self
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(Color.gray.opacity(0.3), lineWidth: 1)
                    .background(Color(.secondarySystemBackground).cornerRadius(10))
            )
    }
    
    var inputPanelStyle: some View {
        self
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.systemBackground))
    }
}

extension String {
    var trimmed: String {
        self.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// Остальной код (ChatMessageRow) остается без изменений
//struct ChatView: View {
//    @EnvironmentObject private var chatService: ChatService
//    @EnvironmentObject private var socketController: SocketController
//    @State private var usermessage: String = ""
//    @State private var showDocumentPicker = false
//    
//   
//    
//    var body: some View {
//        
//        VStack(spacing: 0) {
//        // 🔼 ДОБАВЛЕННЫЕ ЭЛЕМЕНТЫ НАД СКРОЛЛОМ
//            HStack {
//                
//                Text("Чат с роботом: \(String(socketController.selectedRobot?.robot_id.prefix(4) ?? "робот не подключен"))…")
//                    .font(.headline)
//                    .padding(.leading, 16)
//                
//                Circle()
//                    .frame(width: AppConfig.ChatView.connectionIndicatorCircleWidth, height: AppConfig.ChatView.connectionIndicatorCircleHeight)
//                    .foregroundColor(socketController.connectionManager.isConnected ? AppConfig.SocketView.connectionIndicatorConnectColor : AppConfig.SocketView.connectionIndicatorDisconnectColor)
//            }
//            .padding(.vertical, 8)
//            .background(Color(.systemBackground))
//                
// 
//            
//            // область Сообщения
//            ScrollViewReader { proxy in
//                ScrollView {
//                    LazyVStack(spacing: 8) {
//                        ForEach(chatService.messages) { message in
//                            ChatMessageRow(message: message, userName: chatService.authService.userLogin)
//                        }
//                    }
//                    .padding(.vertical, 8)
//                }
//                .background(AppConfig.ChatView.chatBackground)
//                .overlay(
//                    RoundedRectangle(cornerRadius: 12)
//                        .stroke(Color.gray.opacity(0.5), lineWidth: 2)
//                )
//                .padding(.horizontal, 8)
//                .onChange(of: chatService.messages) { _, newMessages in
//                    if !newMessages.isEmpty {
//                        withAnimation {
//                            proxy.scrollTo(newMessages.last?.id, anchor: .bottom)
//                        }
//                    }
//                }
//            }
//            .frame(maxHeight: .infinity)
//            
//            // Панель ввода с четкими границами
//            HStack(spacing: 12) {
//                // Поле ввода с рамкой
//                ZStack(alignment: .topLeading) {
//                    TextEditor(text: $usermessage)
//                        .frame(minHeight: 40, maxHeight: 100)
//                        .padding(.horizontal, 8)
//                        .padding(.vertical, 8)
//                        .scrollContentBackground(.hidden)
//                        .background(Color.clear)
//                    
//                    if usermessage.isEmpty {
//                        Text("Enter message...")
//                            .foregroundColor(.gray)
//                            .padding(.horizontal, 12)
//                            .padding(.vertical, 12)
//                            .allowsHitTesting(false)
//                    }
//                }
//                .background(
//                    RoundedRectangle(cornerRadius: 10)
//                        .strokeBorder(Color.gray.opacity(0.3), lineWidth: 1)
//                        .background(Color(.secondarySystemBackground).cornerRadius(10))
//                )
//                
//                // Кнопка отправки
//                Button(action: sendMessage) {
//                    Image(systemName: "arrow.up.circle.fill")
//                        .font(.system(size: 32))
//                        .foregroundColor(usermessage.trimmed.isEmpty ? .gray : .blue)
//                }
//                .disabled(usermessage.trimmed.isEmpty)
//            }
//            .padding(.horizontal, 12)
//            .padding(.vertical, 8)
//            .background(Color(.systemBackground))
//        }
//        .background(Color(.systemBackground))
//    }
//    
//    
//    private func sendMessage() {
//        let trimmed = usermessage.trimmed
//        guard !trimmed.isEmpty else { return }
//
//        let chatMessage = ChatMessage(
//            sender: .user,
//            text: trimmed,
//            time: Date()
//        )
//        chatService.messages.append(chatMessage)
//        chatService.sendMessageToRobot(message: trimmed)
//        usermessage = ""
//    }
//
//}
//
//extension String {
//    var trimmed: String {
//        self.trimmingCharacters(in: .whitespacesAndNewlines)
//    }
//}

