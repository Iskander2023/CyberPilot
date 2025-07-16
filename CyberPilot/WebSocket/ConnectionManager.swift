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
    @Published var remoteURL = AppConfig.Addresses.serverAddress
    private let logger = CustomLogger(logLevel: .info, includeMetadata: false)
    var cancellables = Set<AnyCancellable>()
    var token: String?
    private let socketManager: SocketManager
    
    init(authService: AuthService, socketManager: SocketManager) {
        self.socketManager = SocketManager(authService: authService, connectionMode: .withRegistration(token: authService.token ?? ""))
        setupTokenBinding(from: authService)
        setupSocketObservers()
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
            remoteURL = "ws://selekpann.tech:2000"
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
