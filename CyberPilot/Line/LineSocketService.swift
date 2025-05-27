//
//  LineSocketService.swift
//  CyberPilot
//
//  Created by Aleksandr Chumakov on 27/05/25.
//

import Foundation

class LineSocketService: ObservableObject {
    var authServise: AuthService
    private var socketManager: SocketManager?
    private let logger = CustomLogger(logLevel: .info, includeMetadata: false)
    private var socketIp: String = "ws://172.16.17.79:8765"
    var onLineMessageReceived: (([[[Double]]], CGPoint) -> Void)?
    
    init(authServise: AuthService) {
        self.authServise = authServise
        socketManager = SocketManager(authService: authServise)
    }
    
    func startSocket() {
        guard let socketManager = socketManager else { return }
        socketManager.connectSocket(urlString: socketIp)
        socketManager.onLineMessageReceived = { [weak self] segments, center in
            guard self != nil else { return }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            guard let self = self else { return }
            if !socketManager.isConnected {
                socketManager.disconnectSocket()
                self.logger.error("ℹ️ Сокет не подключён через 5 секунд — соединение прервано")
            } else {
                self.logger.info("ℹ️ Сокет успешно подключён")
            }
        }
    }
    
    
    
    func stopSocket() {
        if let socketManager = socketManager, socketManager.isConnected {
            socketManager.disconnectSocket()
            logger.info("ℹ️ Загрузка линий остановлена и сокет отключён")
        } else {
            logger.info("ℹ️ Загрузка линий остановлена (сокет уже был отключён)")
        }
    }
}
