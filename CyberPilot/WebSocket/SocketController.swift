//  SSHViewController.swift
//  SSHConnector
//  Created by Aleksandr Chumakov on 18.03.2025.

import SwiftUI
import Combine
import WebKit


final class SocketController: ObservableObject {
    let socketManager: SocketManager
    let connectionManager: ConnectionManager
    let videoStreamManager: VideoUrlManager
    let commandSender: CommandSender
    var errorManager: ErrorManager
    
    @Published var robotSuffix = ""
    @Published private(set) var isLoading = false
    @Published var selectedRobot: Robot? // данные робота { "robot_id": str, "camera_url": str, "status": str, "last_updated": str }
    
    let logger = CustomLogger(logLevel: .info, includeMetadata: false)
    
    private var cancellables = Set<AnyCancellable>()
    
    init(authService: AuthService,socketManager: SocketManager, connectionManager: ConnectionManager) {
        self.connectionManager = connectionManager
        self.socketManager = socketManager
        self.videoStreamManager = VideoUrlManager(authService: authService)
        self.errorManager = ErrorManager()
        self.commandSender = CommandSender(socketManager: socketManager)
        
        setupMessageHandlers(socketManager: socketManager)
    }
    
    

    func setCurrentRobot(_ robot: Robot) {
        self.selectedRobot = robot
        connectionManager.setRobotID(robot.robot_id)
        videoStreamManager.setCameraUrl(robot.camera_url)
    }

    
    private func setupMessageHandlers(socketManager: SocketManager) {
        socketManager.receivedMessages
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                self?.handleSocketMessage(message)
            }
            .store(in: &cancellables)
    }
    
    /// Добавление входящего сообщения от робота  в список сообщений
//    private func handleChatMessage(message: [String: Any]) {
//        guard let text = message["text"] as? String else {
//            errorManager.show("Chat message missing 'text' field")
//            return
//        }
//    }

    
    private func handleSocketMessage(_ message: [String: Any]) {
        logger.info("\(message)")
        guard let typeValue = message["type"] else {
            errorManager.show("Invalid message: missing 'type' key")
            return
        }
        
        guard let type = typeValue as? String else {
            errorManager.show("Invalid message: 'type' must be a String, got \(typeValue)")
            return
        }
        
        print("Received message of type: \(type), full message: \(message)")

        switch type {
        case "error":
            handleErrorMessage(message)
            
//        case "chat":
//            handleChatMessage(message: message)

//        case "status":
//            handleStatusUpdate(message)

        // Добавь другие типы, если нужно
        default:
            errorManager.show("Unknown message type: \(type)")
        }
    }

    
    func updateRobotSuffix() {
        let parts = connectionManager.socketURL.split(separator: ".")
        if let lastPart = parts.last, let lastChar = lastPart.last, lastChar.isNumber {
            robotSuffix = String(lastChar)
        } else {
            robotSuffix = ""
        }
    }
    
    
    private func handleErrorMessage(_ message: [String: Any]) {
        let errorMessage = message["message"] as? String ?? "Unknown error"
        if errorMessage == "robot not found" {
            errorManager.show("Нет доступных роботов")
        }
    }
}
