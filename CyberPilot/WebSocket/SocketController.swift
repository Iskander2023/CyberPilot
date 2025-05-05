//  SSHViewController.swift
//  SSHConnector
//  Created by Aleksandr Chumakov on 18.03.2025.

import SwiftUI
import Combine
import WebKit


final class SocketController: ObservableObject {
    let logger = CustomLogger(logLevel: .info, includeMetadata: false)
    @Published var isConnected = false
    @Published var host = "robot3.local"
    @Published var remoteURL = "ws://selekpann.tech:2000"
    @Published var robotSuffix = ""
    @Published var isLoading = false
    @Published var showError = false
    @Published var errorMessage = ""
    @Published var videoURL = ""
    @Published private var robotManager = RobotManager()
    private var cancellables = Set<AnyCancellable>()
    private let socketManager: SocketManager
    public let commandSender: CommandSender
    
    init(robotManager: RobotManager) {
        self.robotManager = robotManager
        self.socketManager = SocketManager(robotManager: robotManager)
        self.commandSender = CommandSender(socketManager: socketManager)
        setupSocketObservers()
    }
    
    func connectionTypeChanged() {
        
    }
    

    func connect(isLocal: Bool) {
        isLoading = true
        if !isLocal {
            connectToLocalRobot()
        } else {
            connectToRemoteServer()
        }
    }

    
    func disconnect() {
        socketManager.disconnectSocket()
        commandSender.stopIdleStateSending()
        commandSender.stopRepeatCommandSending()
        isConnected = false
        videoURL = ""
    }
    

    func connectionTypeChanged(isLocal: Bool) {
        if isLocal {
            host = "robot3.local"
            videoURL = ""
        } else {
            remoteURL = "ws://selekpann.tech:2000"
            videoURL = ""
        }
    }

    
    func updateRobotSuffix() {
        let parts = host.split(separator: ".")
        if let lastPart = parts.last, let lastChar = lastPart.last, lastChar.isNumber {
            robotSuffix = String(lastChar)
        } else {
            robotSuffix = ""
        }
    }
    

    private func setupSocketObservers() {
        socketManager.connectionStatus
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isConnected in
                self?.handleConnectionStatus(isConnected: isConnected)
            }
            .store(in: &cancellables)
        
        socketManager.receivedMessages
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                self?.handleSocketMessage(message)
            }
            .store(in: &cancellables)
    }
    
    
    private func handleConnectionStatus(isConnected: Bool) {
        isLoading = false
        self.isConnected = isConnected
        
        if isConnected {
            videoURL = self.videoURL
            commandSender.server_robot_available = true
        } else {
            commandSender.server_robot_available = false
            videoURL = ""
        }
    }
    
    
    private func handleSocketMessage(_ message: [String: Any]) {
        if let type = message["type"] as? String {
            switch type {
            case "robotList":
                handleRobotList(message)
            case "error":
                showError(message["message"] as? String ?? "Unknown error")
            default: break
            }
        }
    }
    
    
    private func connectToLocalRobot() {
        socketManager.startResolvingIP(for: host)
        let port = getPort(from: host)
        let urlString = "ws://\(host):\(port)"
        socketManager.connectSocket(urlString: urlString)
    }
    
    
    private func connectToRemoteServer() {
//        guard let token = self.token else {
//                print("❌ Токен отсутствует")
//                return
//            }
        //let robotId = "robot1"
        socketManager.connectSocket(urlString: remoteURL)
        //let message = ServerRegisterCommand().registerServerMsg(token: token, robotId: robotId)
        //logger.info("\(message)")
        //self.socketManager.sendJSONCommand(message) // регистрация
        //logger.info("1")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.socketManager.sendJSONCommand(ServerRegisterCommand().listMsg) //
        }
    }
    
    
    private func getPort(from host: String) -> String {
        let parts = host.split(separator: ".")
        guard let lastPart = parts.last else { return "80" }
        return "8" + String(lastPart)
    }
    
    
    
    private func handleRobotList(_ message: [String: Any]) {
        guard let robots = message["robots"] as? [Any], !robots.isEmpty else {
            showError("Нет доступных роботов")

            disconnect() // вернуть на место после тестов!!!
            
            return
        }
        logger.info("2")
        socketManager.sendJSONCommand(ServerRegisterCommand().registerOperatorMsg)
    }
    
    
    private func showError(_ message: String) {
        errorMessage = message
        showError = true
    }
}
