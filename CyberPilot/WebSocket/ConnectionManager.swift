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
    @Published var socketURL = ""
    
    private let socketManager: SocketManager
    private let logger = CustomLogger(logLevel: .info, includeMetadata: false)
    var token: String?
    var robotId: String = ""
    var cancellables = Set<AnyCancellable>()
    
    
    init(authService: AuthService, socketManager: SocketManager) {
        self.socketManager = socketManager
        setupTokenBinding(from: authService)
        setupSocketObservers()
    }
    
    

    
    /// формирование url для подключения к сокету робота
    func updateSocketURL() {
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
            socketURL = url
            logger.debug("Сформирован URL сокета: \(socketURL)")
        }
    }


    /// устанавливает выбраного робота и запускает метод формирования url
    func setRobotID(_ robotID: String) {
        logger.debug("Установлен robotID: \(robotID)")
        self.robotId = robotID
        updateSocketURL()
    }
    
    /// метод обновления токена
    func updateToken(_ newToken: String?) {
        self.token = newToken
        logger.debug("Token обновлён: \(newToken ?? "nil")")
    }
    
    /// отключение от сокета
    func disconnect() {
        socketManager.disconnectSocket()
    }
    
    /// подключение к сокету
    func connect(completion: @escaping (Bool) -> Void) {
            logger.debug("Подключение к сокету по URL: \(socketURL)")
            socketManager.connectSocket(urlString: socketURL, completion: completion)
        }
    
    
    /// метод проверки активного подключения сокета
    private func setupSocketObservers() {
        socketManager.$isConnected
            .receive(on: DispatchQueue.main)
            .assign(to: \.isConnected, on: self)
            .store(in: &cancellables)
    }
}





//private func getPort(from host: String) -> String {
//        let parts = host.split(separator: ".")
//        guard let lastPart = parts.last else { return "80" }
//        return "8" + String(lastPart)
//    }
