//
//  CommandSender.swift
//  Robot_Controller
//
//  Created by Aleksandr Chumakov on 1/04/25.
//

import Foundation

final class CommandSender {
    let logger = CustomLogger(logLevel: .info, includeMetadata: false)
    private weak var socketManager: SocketManager?
    //private var connectionType: ConnectionType
    
    init(socketManager: SocketManager) {
        self.socketManager = socketManager
    }

    
//    func moveForward() { send(Command.moveForward) }
//    func moveBackward() { send(Command.moveBackward) }
//    func turnLeft() { send(Command.turnLeft) }
//    func turnRight() { send(Command.turnRight) }
//    func stopTheMovement() {send(Command.stopTheMovement)}
    
    func moveForward() { sendJSONCommand(ServerCommand.serverForward) }
    func moveBackward() { sendJSONCommand(ServerCommand.serverBackward) }
    func turnLeft() { sendJSONCommand(ServerCommand.serverLeft) }
    func turnRight() { sendJSONCommand(ServerCommand.serverRight) }
    func stopTheMovement() {sendJSONCommand(ServerCommand.serverStop)}
    
    
    func sendJSONCommand(_ data: [String: Any]) {
        guard let jsonData = try? JSONSerialization.data(withJSONObject: data, options: []),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
              self.logger.info("Ошибка: не удалось закодировать JSON")
            return
        }
        socketManager?.sendCommand(jsonString)
    }
    
    private func send(_ command: String) {
        socketManager?.sendCommand(command)
    }
}

struct ServerCommand {
    
    static let serverForward: [String: Any] = [
        "type": "message",
        "data": [
            "keys": [
                "w": true,
                "s": false,
                "a": false,
                "d": false,
                "e": false
            ]
        ]
    ]
    static let serverBackward: [String: Any] = [
        "type": "message",
        "data": [
            "keys": [
                "w": false,
                "s": true,
                "a": false,
                "d": false,
                "e": false
            ]
        ]
    ]
    static let serverLeft: [String: Any] = [
        "type": "message",
        "data": [
            "keys": [
                "w": false,
                "s": false,
                "a": true,
                "d": false,
                "e": false
            ]
        ]
    ]
    static let serverRight: [String: Any] = [
        "type": "message",
        "data": [
            "keys": [
                "w": false,
                "s": false,
                "a": false,
                "d": true,
                "e": false
            ]
        ]
    ]
    static let serverStop: [String: Any] = [
        "type": "message",
        "data": [
            "keys": [
                "w": false,
                "s": false,
                "a": false,
                "d": false,
                "e": true
            ]
        ]
    ]
    
}

struct Command {
    static let moveForward = "iosMoveForward"
    static let moveBackward = "iosMoveBackward"
    static let turnLeft = "iosTurnLeft"
    static let turnRight = "iosTurnRight"
    static let stopTheMovement = "iosStopMovement"
    
    
}
