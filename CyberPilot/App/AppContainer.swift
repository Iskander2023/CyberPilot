//
//  AppContainer.swift
//  CyberPilot
//
//  Created by Aleksandr Chumakov on 21/05/25.
//
import SwiftUI


final class AppContainer: ObservableObject {
    let authService: AuthService
    let alertManager: AlertManager
    let lineStore: LineManager
    let chatService: ChatService
    let socketController: SocketController
    let socketManager: SocketManager
    let connectionManager: ConnectionManager
    let touchController: TouchController
    let bluetoothManager: BluetoothManager
    let mapManager: MapManager
    let mapZoneHandler: MapZoneHandler
    let voiceControlManager: VoiceService
    let voiceControlViewModel: VoiceViewModel
    let loginManager: LoginManager
    let userRegistrationManager: UserRegistrationManager
    let robotListViewModel: RobotListViewModel
    

    init() {
        self.authService = AuthService()
        self.alertManager = AlertManager()
        self.socketManager = SocketManager(authService: authService)
        self.lineStore = LineManager(authService: authService)
        self.connectionManager = ConnectionManager(authService: authService, socketManager: socketManager)
        self.socketController = SocketController(authService: authService, socketManager: socketManager, connectionManager: connectionManager)
        self.touchController = TouchController(commandSender: socketController.commandSender, timerDelay: 0.2)
        self.bluetoothManager = BluetoothManager()
        self.mapManager = MapManager(authService: authService)
        self.mapZoneHandler = MapZoneHandler(mapManager: mapManager)
        self.chatService = ChatService(authService: authService, socketController: socketController, commandSender: socketController.commandSender)
        self.voiceControlManager = VoiceService(commandSender: socketController.commandSender)
        self.voiceControlViewModel = VoiceViewModel(voiceManager: voiceControlManager)
        self.loginManager = LoginManager(authService: authService)
        self.userRegistrationManager = UserRegistrationManager(authService: authService)
        self.robotListViewModel = RobotListViewModel()

    }
}
