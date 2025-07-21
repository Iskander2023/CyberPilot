//
//  ChatService.swift
//  CyberPilot
//
//  Created by Aleksandr Chumakov on 16/07/25.
//

import Foundation


class ChatService: ObservableObject {
    private var message: String = ""
    var authService: AuthService
    private var socketManager: SocketManager

    init(authService: AuthService, socketManager: SocketManager) {
        self.authService = authService
        self.socketManager = socketManager
    }

    func sendMessageToRobot(message: String) {
        socketManager.sendCommand(message)
    }
    
    func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: date)
    }

}

struct Message: Identifiable {
    let id = UUID()
    let text: String
    let date: Date
}



