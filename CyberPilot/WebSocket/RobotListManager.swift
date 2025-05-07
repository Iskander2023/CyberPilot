//
//  RobotListManager.swift
//  CyberPilot
//
//  Created by Aleksandr Chumakov on 7/05/25.
//
import SwiftUI



final class RobotListManager: ObservableObject {
    private let socketManager: SocketManager
    private let logger = CustomLogger(logLevel: .info, includeMetadata: false)
    
    @Published var availableRobots: [[String: Any]] = []
    @Published var showRobotPicker = false
    
    init(socketManager: SocketManager) {
        self.socketManager = socketManager
    }
    
    func requestRobotList() {
        let listMsg: [String: Any] = ["type": "listRobots"]
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.socketManager.sendJSONCommand(listMsg)
        }
    }
    
    func handleRobotListMessage(_ message: [String: Any]) {
        guard let robots = message["robots"] as? [[String: Any]] else {
            logger.error("Неверный формат списка роботов")
            return
        }
        
        availableRobots = robots
        showRobotPicker = !robots.isEmpty
    }
    
    
    func registerAsOperator(for robot: [String: Any]) {
        guard let robotId = robot["robotId"] as? String else {
            logger.error("Не удалось получить ID робота")
            return
        }
        
        let registerMsg: [String: Any] = [
            "type": "register",
            "role": "operator",
            "robotId": robotId
        ]
        socketManager.sendJSONCommand(registerMsg)
        showRobotPicker = false
    }
}
