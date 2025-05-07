//
//  ConnectionManager.swift
//  CyberPilot
//
//  Created by Aleksandr Chumakov on 7/05/25.
//
import SwiftUI
import Combine


final class ConnectionManager: ObservableObject {
    private let logger = CustomLogger(logLevel: .info, includeMetadata: false)
    private let socketManager: SocketManager
    private var cancellables = Set<AnyCancellable>()
    
    @Published var isConnected = false
    @Published var host = "robot3.local"
    @Published var remoteURL = "ws://selekpann.tech:2000"
    
    init(socketManager: SocketManager) {
        self.socketManager = socketManager
        setupSocketObservers()
    }
    
    func connect(isLocal: Bool) {
        print("\(isLocal)")
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
        print("connectToLocalRobot")
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
