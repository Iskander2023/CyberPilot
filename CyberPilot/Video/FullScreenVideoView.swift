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
    var distance: CGFloat?
    let maxSize: CGFloat = 250
    let minSize: CGFloat = 100
    let maxSizeTach: CGFloat = 125
    
    var commandSender: CommandSender
    
    @Environment(\.presentationMode) var presentationMode
    
    @State private var touchLocation: CGPoint? = nil
    @State private var initialTouchPoint: CGPoint = .zero
    @State private var currentAngle: CGFloat = 0.0
    @State private var previousAngle: CGFloat?
    @State private var touchIndicatorSize: CGFloat = 100
    @State private var touchIndicatorVisible = false
    @State private var touchIndicatorPosition: CGPoint = .zero
    @State private var angleUpdateTimer: Timer?
    @State private var arrowLength: CGFloat = 0.0
    @State private var isArc = false
    @State private var curveAngle: CGFloat = 0.0
    
    var body: some View {
        ZStack {
            // 1. WebView - самый нижний слой
            WebViewRepresentable(urlString: videoURL ?? "")
                .edgesIgnoringSafeArea(.all)
                .allowsHitTesting(false) // Отключаем взаимодействие
            
           //перспектива
            perspective()
            
            
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
            DirectionLabels()
        }
    }
    
    
    private func perspective() -> some View {
        GeometryReader { geometry in
            DirectionArc(
                curveAngle: curveAngle,
                width: geometry.size.width,
                height: geometry.size.height
            )
        }
        .allowsHitTesting(false)
    }
    
    
    private func DirectionArc(curveAngle: Double, width: CGFloat, height: CGFloat) -> some View {
        let radius: CGFloat = 350
        let centerY = height - 200
        
        // Корректируем угол так, чтобы:
        // - 270° (прямо) → 0
        // - 0° (вправо) → +π/2
        // - 180° (влево) → -π/2
        // - 90° (назад) → ±π
        var adjustedAngle = CGFloat(curveAngle - 3 * .pi / 2)
        if adjustedAngle < -.pi { adjustedAngle += 2 * .pi }
        
        return Path { path in
            let start = CGPoint(x: width * 0.2, y: height - 40)
            
            let sensitivity: CGFloat = 0.8
            let angle = adjustedAngle * sensitivity
            
            let end = CGPoint(
                x: width * 0.2 + radius * sin(angle) * 0.3,
                y: centerY - radius * cos(angle) * 0.3
            )
            
            let control = CGPoint(
                x: (start.x + end.x) / 2,
                y: (start.y + end.y) / 2 - abs(radius * 0.3 * angle)
            )
            
            path.move(to: start)
            path.addQuadCurve(to: end, control: control)
        }
        .stroke(Color.blue, lineWidth: 5)
    }



    private func DirectionLabels() -> some View {
        ZStack {
            ForEach(0..<8) { i in
                let angle = Double(i) * .pi / 4 - .pi / 8 // каждый шаг — 45°
                let radius = touchIndicatorSize / 2 - 15
                let center = CGPoint(x: touchIndicatorSize / 2, y: touchIndicatorSize / 2)
                let x = center.x + radius * cos(angle)
                let y = center.y + radius * sin(angle)
                Circle()
                    .frame(width: 6, height: 6)
                    .foregroundColor(.green)
                    .position(x: x, y: y)
            }
        }
        .frame(width: touchIndicatorSize, height: touchIndicatorSize)
        .position(touchIndicatorPosition)
    }


    private func DirectionArrow() -> some View {
        Path { path in
            let center = CGPoint(x: touchIndicatorSize / 2, y: touchIndicatorSize / 2)
            path.move(to: center)

            let endPoint = CGPoint(
                x: center.x + arrowLength * cos(currentAngle),
                y: center.y + arrowLength * sin(currentAngle)
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
        arrowLength = distance
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
        curveAngle = angle
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




