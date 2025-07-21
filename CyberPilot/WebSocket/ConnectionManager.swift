//
//  ConnectionManager.swift
//  CyberPilot
//
//  Created by Aleksandr Chumakov on 7/05/25.
//
import SwiftUI
import Combine


final class ConnectionManager: ObservableObject, TokenUpdatable {
    @Published var isConnected = false
    @Published var host = AppConfig.Addresses.localAddress
    @Published var remoteURL = ""
    private let logger = CustomLogger(logLevel: .debug, includeMetadata: false)
    var cancellables = Set<AnyCancellable>()
    var token: String?
    var robotId: String = ""
    private let socketManager: SocketManager
    
    init(authService: AuthService, socketManager: SocketManager) {
        self.socketManager = socketManager
        setupTokenBinding(from: authService)
        setupSocketObservers()
    }
    
    
    func updateRemoteURL() {
        guard let token = self.token, !robotId.isEmpty else {
            logger.warn("robotId или token не установлены")
            return
        }
        guard var components = URLComponents(string: AppConfig.Addresses.wsUrl) else {
            logger.error("Невозможно создать URLComponents из wsUrl")
            return
        }
        var pathComponents = components.path.split(separator: "/").map(String.init)
        pathComponents.append(robotId)
        components.path = "/" + pathComponents.joined(separator: "/")
        components.queryItems = [URLQueryItem(name: "token", value: token)]
        if let url = components.url?.absoluteString {
            remoteURL = url
            logger.info("Сформирован URL сокета: \(remoteURL)")
        }
    }


    
    func setRobotID(_ robotID: String) {
        logger.info("Установлен robotID: \(robotID)")
        self.robotId = robotID
        updateRemoteURL()
    }
    
    
    func updateToken(_ newToken: String?) {
        self.token = newToken
        logger.debug("Token обновлён: \(newToken ?? "nil")")
    }
    
    
    func connect(isLocal: Bool) {
        if isLocal {
            connectToLocalRobot()
        } else {
            connectToRemote()
        }
    }
    
    
    func connectionTypeChanged(isLocal: Bool) {
        if isLocal {
            host = "robot3.local"
        } else {
            guard let token = self.token, !robotId.isEmpty else {
                logger.warn("Robot ID или токен не установлены")
                return
            }
            guard var components = URLComponents(string: AppConfig.Addresses.wsUrl) else {
                logger.error("Невозможно создать URLComponents из wsUrl")
                return
            }
            
            var pathComponents = components.path.split(separator: "/").map(String.init)
            pathComponents.append(robotId)
            components.path = "/" + pathComponents.joined(separator: "/")
            components.queryItems = [URLQueryItem(name: "token", value: token)]
            
            if let url = components.url?.absoluteString {
                remoteURL = url
                logger.info("Сформирован URL сокета: \(remoteURL)")
            }
        }
    }


    func disconnect() {
        socketManager.disconnectSocket()
    }
    
    
    private func connectToLocalRobot() {
        socketManager.startResolvingIP(for: host)
        let port = getPort(from: host)
        let urlString = "ws://\(host):\(port)"
        socketManager.connectSocket(urlString: urlString)
    }
    
    
    private func connectToRemote() {
        logger.info("Подключение к сокету по URL: \(remoteURL)")
        socketManager.connectSocket(urlString: remoteURL)
    }
    
    
    private func getPort(from host: String) -> String {
        let parts = host.split(separator: ".")
        guard let lastPart = parts.last else { return "80" }
        return "8" + String(lastPart)
    }
    
    
    private func setupSocketObservers() {
        socketManager.connectionStatus
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isConnected in
                self?.isConnected = isConnected
            }
            .store(in: &cancellables)
    }
}
