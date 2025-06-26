//  SSHViewController.swift
//  SSHConnector
//  Created by Aleksandr Chumakov on 18.03.2025.

import SwiftUI
import Combine
import WebKit


final class SocketController: ObservableObject {
    @Published var robotSuffix = ""
    @Published var connectionManager: ConnectionManager
    @Published var robotListManager: RobotListManager
    @Published var videoStreamManager: VideoStreamManager
    @Published var errorManager: ErrorManager
    @Published var commandSender: CommandSender
    @Published private(set) var isLoading = false
    let logger = CustomLogger(logLevel: .info, includeMetadata: false)
    private var cancellables = Set<AnyCancellable>()
    
    init(authService: AuthService) {
        let socketManager = SocketManager(authService: authService)
        self.connectionManager = ConnectionManager(authService: authService, socketManager: socketManager)
        self.robotListManager = RobotListManager(socketManager: socketManager)
        self.videoStreamManager = VideoStreamManager(robotManager: authService)
        self.errorManager = ErrorManager()
        self.commandSender = CommandSender(socketManager: socketManager)
        
        setupMessageHandlers(socketManager: socketManager)
    }
    
    private func setupMessageHandlers(socketManager: SocketManager) {
        socketManager.receivedMessages
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                self?.handleSocketMessage(message)
            }
            .store(in: &cancellables)
    }
    
    private func handleSocketMessage(_ message: [String: Any]) {
        guard let type = message["type"] as? String else {
            errorManager.show("Invalid message format: missing 'type'")
            return
        }
        
        switch type {
        case "robotList":
            robotListManager.handleRobotListMessage(message)
        case "error":
            handleErrorMessage(message)
        default:
            errorManager.show("Unknown message type: \(type)")
        }
    }
    
    
    // симуляция списка роботов
    func simulateRobotListResponse() {
        let mockRobots: [[String: Any]] = [
            ["robotId": "robot1"],
            ["robotId": "robot2"]
        ]
        logger.info("mockMessage")
        let mockMessage: [String: Any] = ["type": "robotList", "robots": mockRobots]
        robotListManager.showRobotPicker = true
        updateRobotSuffix()
        handleSocketMessage(mockMessage)
    }
    
    
    func updateRobotSuffix() {
        let parts = connectionManager.host.split(separator: ".")
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
