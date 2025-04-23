//
//  VideoViewController.swift
//  CyberPilot
//
//  Created by Aleksandr Chumakov on 16/04/25.
//
import SwiftUI
import WebKit


struct FullScreenVideoView: View {
    var videoURL: String?
    let maxSize: CGFloat = 250
    let minSize: CGFloat = 100
    let maxSizeTach: CGFloat = 125
    
    var commandSender: CommandSender
    
    @Environment(\.presentationMode) var presentationMode
    
    @State private var leftOverlayAngle: CGFloat = 0
    @State private var rightOverlayAngle: CGFloat = 0
    @State private var leftOverlayActive = false
    @State private var rightOverlayActive = false
    @State private var touchLocation: CGPoint? = nil
    
    @State private var initialTouchPoint: CGPoint = .zero
    @State private var currentAngle: CGFloat = 0.0
    @State private var previousAngle: CGFloat?
    @State private var touchIndicatorSize: CGFloat = 100
    @State private var touchIndicatorVisible = false
    @State private var touchIndicatorPosition: CGPoint = .zero
    @State private var angleUpdateTimer: Timer?

    
    var body: some View {
        ZStack {
            // 1. WebView - самый нижний слой
            WebViewRepresentable(urlString: videoURL ?? "")
                .edgesIgnoringSafeArea(.all)
                .allowsHitTesting(false) // Отключаем взаимодействие
            
            // 2. Touch Area - основной слой для жестов
            Color.clear
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    handleTouchChanged(value)
                                }
                                .onEnded { _ in
                                    resetTouchPad()
                                }
                )
            // 3. Визуализация касания
            if touchIndicatorVisible {
                touchIndicatorView()
            }

            // 4. UI элементы - самый верхний слой
            CloseButton {
                presentationMode.wrappedValue.dismiss()
            }
        }
        .background(Color.black)
    }
    
    
    private func touchIndicatorView() -> some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.5), lineWidth: 2)
                .background(Circle().fill(Color.white.opacity(0.05)))
                .frame(width: touchIndicatorSize, height: touchIndicatorSize)
                .position(touchIndicatorPosition)
                .transition(.opacity)

            DirectionArrow()
        }
    }

    private func DirectionArrow() -> some View {
        Path { path in
            let center = CGPoint(x: touchIndicatorSize / 2, y: touchIndicatorSize / 2)
            path.move(to: center)

            let endPoint = CGPoint(
                x: center.x + 50 * cos(currentAngle),
                y: center.y + 50 * sin(currentAngle)
            )
            path.addLine(to: endPoint)

            let arrowHeadLength: CGFloat = 15
            let angle1 = currentAngle + .pi * 0.8
            let angle2 = currentAngle + .pi * 1.2

            path.move(to: endPoint)
            path.addLine(to: CGPoint(
                x: endPoint.x + arrowHeadLength * cos(angle1),
                y: endPoint.y + arrowHeadLength * sin(angle1)
            ))

            path.move(to: endPoint)
            path.addLine(to: CGPoint(
                x: endPoint.x + arrowHeadLength * cos(angle2),
                y: endPoint.y + arrowHeadLength * sin(angle2)
            ))
        }
        .stroke(Color.blue, lineWidth: 4)
        .frame(width: touchIndicatorSize, height: touchIndicatorSize)
        .position(touchIndicatorPosition)
    }

    
    private func handleTouchChanged(_ value: DragGesture.Value) {
        if !touchIndicatorVisible {
            initializeTouchIndicator(value: value)
        }
        
        updateTouchIndicatorSize(currentPoint: value.location)
        updateAngle(for: value.location)
    }


    /// Инициализирует индикатор касания.
    private func initializeTouchIndicator(value: DragGesture.Value) {
        initialTouchPoint = value.startLocation
        touchIndicatorPosition = initialTouchPoint
        touchIndicatorSize = 100
        touchIndicatorVisible = true
        startAngleUpdateTimer()
    }

    /// Обновляет размер индикатора касания.
    private func updateTouchIndicatorSize(currentPoint: CGPoint) {
        let distX = currentPoint.x - initialTouchPoint.x
        let distY = currentPoint.y - initialTouchPoint.y
        var distance = sqrt(distX * distX + distY * distY)
        
     
        if distance > maxSizeTach {
            distance = maxSizeTach
        }
        
        touchIndicatorSize = min(max(minSize, distance * 2), maxSize)
    }

    
    private func updateAngle(for touchLocation: CGPoint) {
        let dx = touchLocation.x - touchIndicatorPosition.x
        let dy = touchLocation.y - touchIndicatorPosition.y
        
        var angle = atan2(dy, dx)
        if angle < 0 {
            angle += 2 * .pi
        }
        
        if let prev = previousAngle {
            var delta = angle - prev
            if delta > .pi {
                delta -= 2 * .pi
            } else if delta < -.pi {
                delta += 2 * .pi
            }
            
            let threshold: CGFloat = 0.1 // Игнорирует незначительные движения, чтобы не было "дребезга" управления 0.05
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

    private func resetTouchPad() {
        angleUpdateTimer?.invalidate()
        angleUpdateTimer = nil
        previousAngle = nil
        
        withAnimation {
            touchIndicatorVisible = false
        }
        
        commandSender.moveForward(isPressed: false)
        commandSender.moveBackward(isPressed: false)
        commandSender.turnLeft(isPressed: false)
        commandSender.turnRight(isPressed: false)
        
    }

    
    private func startAngleUpdateTimer() {
        angleUpdateTimer?.invalidate()
        angleUpdateTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { _ in
            let flags = controlFlags(for: currentAngle)
            updateControls(with: flags)
        }
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
}


struct CloseButton: View {
    var action: () -> Void
    
    var body: some View {
        VStack {
            HStack {
                Button(action: action) {
                    Text("Закрыть")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.black.opacity(0.5))
                        .cornerRadius(8)
                }
                .padding(.top, 16)
                .padding(.leading, 16)
                
                Spacer()
            }
            Spacer()
        }
    }
}




