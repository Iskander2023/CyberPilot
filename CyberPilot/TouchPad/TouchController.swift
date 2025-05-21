//
//  TouchController.swift
//  CyberPilot
//
//  Created by Aleksandr Chumakov on 20/05/25.
//

import SwiftUI


class TouchController: ObservableObject {
    private let commandSender: CommandSender
    var currentAngle: CGFloat = 0.0
    private var previousAngle: CGFloat?
    private var accumulatedRotation: CGFloat = 0
    private var lastUpdateTime: Date?
    let maxSizeTach: CGFloat = 125
    let maxSize: CGFloat = 250
    let minSize: CGFloat = 100

    @Published var touchIndicatorVisible = false
    @Published var touchIndicatorPosition: CGPoint = .zero
    @Published var touchIndicatorSize: CGFloat = 100
    @Published var arrowLength: CGFloat = 0
    @Published var perspectiveLength: Int = 3
    
    private var angleUpdateTimer: Timer?
    
    init(commandSender: CommandSender) {
        self.commandSender = commandSender
    }

    func handleTouchChanged(_ value: DragGesture.Value) {
        if !touchIndicatorVisible {
            initializeTouchIndicator(value: value)
        }
        updateTouchIndicatorSize(currentPoint: value.location)
        updateAngle(for: value.location)
    }

    private func initializeTouchIndicator(value: DragGesture.Value) {
        touchIndicatorPosition = value.startLocation
        touchIndicatorSize = 100
        touchIndicatorVisible = true
        startAngleUpdateTimer()
    }


    private func updateTouchIndicatorSize(currentPoint: CGPoint) {
            let distX = currentPoint.x - touchIndicatorPosition.x
            let distY = currentPoint.y - touchIndicatorPosition.y
            var distance = sqrt(distX * distX + distY * distY)
            if distance > maxSizeTach {
                distance = maxSizeTach
            }
            arrowLength = distance
            updateLenghtPerspective(distance: distance) // меняем длину перспективы
            touchIndicatorSize = min(max(minSize, distance * 2), maxSize)
        }

    private func updateLenghtPerspective(distance: CGFloat) {
        if distance > 50 && distance <= 80 {
            perspectiveLength = 4
        } else if distance > 80 {
            perspectiveLength = 5
        } else {
            perspectiveLength = 3
        }
    }

    private func updateAngle(for touchLocation: CGPoint) {
        let dx = touchLocation.x - touchIndicatorPosition.x
        let dy = touchLocation.y - touchIndicatorPosition.y
        var angle = atan2(dy, dx)
        if angle < 0 {
            angle += 2 * .pi
        }

        let now = Date()
        let deltaTime = lastUpdateTime.map { now.timeIntervalSince($0) } ?? 0
        lastUpdateTime = now

        if let prev = previousAngle {
            var delta = angle - prev
            if delta > .pi {
                delta -= 2 * .pi
            } else if delta < -.pi {
                delta += 2 * .pi
            }

            accumulatedRotation += delta * (deltaTime > 0 ? 1.0 / CGFloat(deltaTime) : 1.0) * 0.1

            let threshold: CGFloat = 0.1
            if abs(delta) > threshold {
                if delta > 0 {
                    commandSender.turnRight(isPressed: true)
                    commandSender.turnLeft(isPressed: false)
                } else {
                    commandSender.turnLeft(isPressed: true)
                    commandSender.turnRight(isPressed: false)
                }
            }
        }
        previousAngle = angle
        currentAngle = angle
        let flags = controlFlags(for: angle)
        updateControls(with: flags)
    }

    func resetTouchPad() {
        stopAngleUpdateTimer()
        previousAngle = nil
        accumulatedRotation = 0
        lastUpdateTime = nil
        perspectiveLength = 3
        currentAngle = 1.5 * .pi
        
        withAnimation(.easeOut(duration: 0.3)) {
            touchIndicatorVisible = false
        }
        stopAllCommands()
    }

    private func stopAngleUpdateTimer() {
        angleUpdateTimer?.invalidate()
        angleUpdateTimer = nil
    }

    private func startAngleUpdateTimer() {
        stopAngleUpdateTimer()
        angleUpdateTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            //self.accumulatedRotation *= 0.95
            if abs(self.accumulatedRotation) < 0.01 {
                self.accumulatedRotation = 0
            }
            let flags = self.controlFlags(for: self.currentAngle)
            self.updateControls(with: flags)
        }
        RunLoop.current.add(angleUpdateTimer!, forMode: .common)
    }

    private func updateControls(with flags: [String: Bool]) {
        commandSender.moveForward(isPressed: flags["forward"] ?? false)
        commandSender.moveBackward(isPressed: flags["backward"] ?? false)
        commandSender.turnLeft(isPressed: flags["left"] ?? false)
        commandSender.turnRight(isPressed: flags["right"] ?? false)
    }

    func controlFlags(for angle: CGFloat) -> [String: Bool] {
        let degrees = angle * 180 / .pi
        var flags = [
            "forward": false,
            "backward": false,
            "left": false,
            "right": false
        ]
        switch degrees {
        case 337.5..<360, 0..<22.5:
            flags["right"] = true
        case 22.5..<67.5:
            flags["right"] = true
            flags["backward"] = true
        case 67.5..<112.5:
            flags["backward"] = true
        case 112.5..<157.5:
            flags["left"] = true
            flags["backward"] = true
        case 157.5..<202.5:
            flags["left"] = true
        case 202.5..<247.5:
            flags["left"] = true
            flags["forward"] = true
        case 247.5..<292.5:
            flags["forward"] = true
        case 292.5..<337.5:
            flags["right"] = true
            flags["forward"] = true
        default:
            break
        }
        return flags
    }

    func stopAllCommands() {
        commandSender.moveForward(isPressed: false)
        commandSender.moveBackward(isPressed: false)
        commandSender.turnLeft(isPressed: false)
        commandSender.turnRight(isPressed: false)
    }

    func onDisappear() {
        stopAngleUpdateTimer()
        stopAllCommands()
    }
}
