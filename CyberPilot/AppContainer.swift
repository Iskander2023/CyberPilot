//
//  AppContainer.swift
//  CyberPilot
//
//  Created by Admin on 21/05/25.
//
import SwiftUI


final class AppContainer: ObservableObject {
    let authService: AuthService
    let alertManager: AlertManager
    let mapManager: MapManager
    let lineStore: LineManager
    let socketController: SocketController
    let socketManager: SocketManager
    let touchController: TouchController
    let bluetoothManager: BluetoothManager

    init() {
        self.authService = AuthService()
        self.alertManager = AlertManager()
        self.mapManager = MapManager(authService: authService)
        self.lineStore = LineManager(authService: authService)
        self.socketController = SocketController(authService: authService)
        self.socketManager = SocketManager(authService: authService)
        self.touchController = TouchController(commandSender: socketController.commandSender, timerDelay: 0.2)
        self.bluetoothManager = BluetoothManager()
    }
}
