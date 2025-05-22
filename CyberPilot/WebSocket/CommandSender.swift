//
//  CommandSender.swift
//  Robot_Controller
//
//  Created by Aleksandr Chumakov on 1/04/25.
//

import Foundation


final class CommandSender {
    let logger = CustomLogger(logLevel: .info, includeMetadata: false)
    private weak var socketManager: SocketManager?
    var server_robot_available = false
    
    private var currentKeysState: [String: Bool] = [
        "w": false,
        "s": false,
        "a": false,
        "d": false,
        "e": false
    ]
    
    private var repeatTimer: Timer?
    private var idleTimer: Timer?
    
    private var isAnyKeyPressed: Bool {
        return currentKeysState.values.contains(true)
    }

    init(socketManager: SocketManager) {
        self.socketManager = socketManager
    }
    
    private func updateKey(_ key: String, isPressed: Bool) {
        if key != "e" {
            currentKeysState["e"] = false
        }
        currentKeysState[key] = isPressed
        
        if key == "e" && isPressed {
            currentKeysState["w"] = false
            currentKeysState["s"] = false
            currentKeysState["a"] = false
            currentKeysState["d"] = false
        }

        sendCurrentState()
        
        guard server_robot_available else {
            //logger.info("⛔️ Робот недоступен, команды не отправляются")
            return
        }
        // Если ни одна кнопка не нажата, запускаем таймер для отправки состояния с false
        if self.server_robot_available {
            if !isAnyKeyPressed {
                startIdleStateSending()
            } else {
                stopIdleStateSending()
                startRepeatCommandSending() // Запуск отправки с интервалом 0.2 секунды для зажатых кнопок
            }
        }
    }

    private func sendCurrentState() {
        let command: [String: Any] = [
            "type": "message",
            "data": [
                "keys": currentKeysState
            ]
        ]
        sendJSONCommand(command)
    }

    func sendJSONCommand(_ data: [String: Any]) {
        guard let jsonData = try? JSONSerialization.data(withJSONObject: data, options: []),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            self.logger.info("Ошибка: не удалось закодировать JSON")
            return
        }
        socketManager?.sendCommand(jsonString)
    }

    // MARK: - Таймер для отправки пустого состояния (когда кнопки не нажаты)
    
    func startIdleStateSending() {
        // Прерываем старый таймер, если он есть
        stopIdleStateSending()
    
        // Настроим таймер, который будет отправлять команду с пустыми кнопками каждые 0.5 секунды
        idleTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.sendIdleState()
        }
        
        RunLoop.current.add(idleTimer!, forMode: .common)
    }

    func stopIdleStateSending() {
        idleTimer?.invalidate()
        idleTimer = nil
    }

    private func sendIdleState() {
        currentKeysState = ["w": false, "s": false, "a": false, "d": false, "e": false]
        sendCurrentState()
    }

    //  Таймер для повторяющейся отправки команд с интервалом 0.2 секунды (для зажатых кнопок)

    private func startRepeatCommandSending() {
        stopRepeatCommandSending()
        
        repeatTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] _ in
            self?.sendCurrentState()
        }
        
        RunLoop.current.add(repeatTimer!, forMode: .common)
    }

    func stopRepeatCommandSending() {
        repeatTimer?.invalidate()
        repeatTimer = nil
    }


    func moveForward(isPressed: Bool) {
        updateKey("w", isPressed: isPressed)
    }

    func moveBackward(isPressed: Bool) {
        updateKey("s", isPressed: isPressed)
    }

    func turnLeft(isPressed: Bool) {
        updateKey("a", isPressed: isPressed)
    }

    func turnRight(isPressed: Bool) {
        updateKey("d", isPressed: isPressed)
    }

    func stopTheMovement() {
        updateKey("e", isPressed: true)
    }
}



struct Command {
    static let moveForward = "iosMoveForward"
    static let moveBackward = "iosMoveBackward"
    static let turnLeft = "iosTurnLeft"
    static let turnRight = "iosTurnRight"
    static let stopTheMovement = "iosStopMovement"
    
    
}
