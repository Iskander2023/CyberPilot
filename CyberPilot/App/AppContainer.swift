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
    let socketController: SocketController
    let socketManager: SocketManager
    let touchController: TouchController
    let bluetoothManager: BluetoothManager
    let mapManager: MapManager
    let mapZoneHandler: MapZoneHandler
    let voiceControlManager: VoiceService
    let voiceControlViewModel: VoiceViewModel
    let loginManager: LoginManager
    let userRegistrationManager: UserRegistrationManager
    let chatService: ChatService
    let robotListViewModel: RobotListViewModel

    init() {
        self.authService = AuthService()
        self.alertManager = AlertManager()
        self.lineStore = LineManager(authService: authService)
        self.socketController = SocketController(authService: authService)
        self.socketManager = SocketManager(authService: authService)
        self.touchController = TouchController(commandSender: socketController.commandSender, timerDelay: 0.2)
        self.bluetoothManager = BluetoothManager()
        self.mapManager = MapManager(authService: authService)
        self.mapZoneHandler = MapZoneHandler(mapManager: mapManager)
        self.voiceControlManager = VoiceService(commandSender: socketController.commandSender)
        self.voiceControlViewModel = VoiceViewModel(voiceManager: voiceControlManager)
        self.loginManager = LoginManager(authService: authService)
        self.userRegistrationManager = UserRegistrationManager(authService: authService)
        self.chatService = ChatService(authService: authService, socketManager: socketManager)
        self.robotListViewModel = RobotListViewModel()

    }
}
