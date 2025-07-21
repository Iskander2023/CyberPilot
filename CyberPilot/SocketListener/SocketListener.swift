//
//  SocketHandler.swift
//  CyberPilot
//
//  Created by Aleksandr Chumakov on 28/05/25.
//

import Foundation

/// класс для тестового соединения с сокетом, реализован для карты и лидара
class SocketListener {
    var authService: AuthService
    private var socketManager: SocketManager?
    private var socketIp: String
    private let logger = CustomLogger(logLevel: .info, includeMetadata: false)
    
    var onMapReceived: (([Int], Int) -> Void)?
    var onLinesReceived: (([[[Double]]], CGPoint) -> Void)?
    
    init(authService: AuthService, socketIp: String) {
        self.authService = authService
        self.socketIp = socketIp
        socketManager = SocketManager(authService: authService) // создание нового подключения со своим IP адресом
        
    }
    
    
    func startListening(for type: SocketDataType) {
        guard let socketManager = socketManager else { return }
        socketManager.connectSocket(urlString: socketIp)
        switch type {
        case .map:
            socketManager.onMapArrayReceived = { [weak self] array, len in
                self?.onMapReceived?(array, len)
            }
        case .lines:
            socketManager.onLineMessageReceived = { [weak self]  segments, center in
                self?.onLinesReceived?(segments, center)
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
            guard let self = self else { return }
            
            if !socketManager.isConnected {
                socketManager.disconnectSocket()
                self.logger.error("❌ Сокет не подключён через 5 секунд — соединение прервано")
            } else {
                self.logger.info("✅ Сокет успешно подключён")
            }
        }
    }
    
    
    func stopListening() {
        if let socketManager = socketManager, socketManager.isConnected {
            socketManager.disconnectSocket()
            logger.info("Загрузка карты остановлена и сокет отключён")
        } else {
            logger.info("Загрузка карты остановлена (сокет уже был отключён)")
        }
    }
}


enum SocketDataType {
    case map
    case lines
}
