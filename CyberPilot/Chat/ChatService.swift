//
//  ChatService.swift
//  CyberPilot
//
//  Created by Aleksandr Chumakov on 16/07/25.
//
import Foundation
import Combine


class ChatService: ObservableObject {
    
    @Published var messages: [ChatMessage] = []
    private var cancellables = Set<AnyCancellable>()
    
    private var message: String = ""
    
    
    let authService: AuthService
    let commandSender: CommandSender
    let socketController: SocketController

    init(authService: AuthService, socketController: SocketController, commandSender: CommandSender) {
        self.authService = authService
        self.socketController = socketController
        self.commandSender = commandSender
        
        // Подписка на только chat-сообщения
        socketController.socketManager.receivedMessages
            .sink { [weak self] json in
                guard let self = self else { return }
                if let type = json["type"] as? String, type == "chat" {
                    let chat = ChatMessage(
                        sender: .robot,
                        text: json["text"] as? String ?? "",
                        time: Date()
                    )

                    DispatchQueue.main.async {
                        self.messages.append(chat)
                    }
                }
            }
            .store(in: &cancellables)
    }

    
    func sendMessageToRobot(message: String) {
        let jsonDict: [String: Any] = [
            "type": "chat",
            "text": message
        ]
        commandSender.sendJSONCommand(jsonDict)
    }

    
    func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: date)
    }

}





