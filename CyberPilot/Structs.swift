//
//  Models.swift
//  Robot_Controller
//
//  Created by Aleksandr Chumakov on 20/01/25.
//

import Foundation
import CoreBluetooth

struct ConnectionStatus {
    var isConnected: Bool = false
    var deviceName: String? = nil
}

struct BatteryStatus {
    var level: Int = 0
    var isCharging: Bool = false
}

struct MotorStatus {
    var isMoving: Bool = false
    var motorError: String? = nil
}

struct ErrorHandling {
    var errorMessage: String? = nil
    var eventLogs: [String] = []
}

struct PeripheralDevice: Identifiable {
    let id = UUID()
    let peripheral: CBPeripheral
    let name: String
    let rssi: Int
    let uuid: UUID
    var isConnected: Bool = false // Состояние подключения
}

struct ServerRegisterCommand {
    let registerServerMsg: [String: Any] = ["type": "register", "role": "server"]
    let listMsg: [String: Any] = ["type": "listRobots"]
    let registerOperatorMsg: [String: Any] = ["type": "register", "role": "operator", "robotId": "KIBORG_YBIVCA"]
}

