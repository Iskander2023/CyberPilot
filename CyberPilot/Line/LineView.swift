//
//  LineView.swift
//  CyberPilot
//
//  Created by Aleksandr Chumakov on 16/05/25.
//
import SwiftUI



struct LineView: View {
    @EnvironmentObject private var robotManager: AuthService
    @EnvironmentObject private var lineStore: LineManager
    @EnvironmentObject private var touchController: TouchController
    
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    private let logger = CustomLogger(logLevel: .info, includeMetadata: false)
    
    
    var body: some View {
        GeometryReader { geometry in
            if lineStore.segments.isEmpty {
                Text("Сегменты не загружены")
                    .frame(width: geometry.size.width, height: geometry.size.height)
            } else {
                ZStack {
                    Path { path in
                        for segment in lineStore.segments {
                            switch segment {
                            case let .line(start, end):
                                let p1 = transformPoint(start.cgPoint, in: geometry)
                                let p2 = transformPoint(end.cgPoint, in: geometry)
                                path.move(to: p1)
                                path.addLine(to: p2)

                            case let .arc(start, end, radius):
                                let p1 = transformPoint(start.cgPoint, in: geometry)
                                let p2 = transformPoint(end.cgPoint, in: geometry)

                                if let (center, clockwise) = ShapeSegment.arcCenter(from: p1,to: p2, radius: radius) {
                                    let startAngle = Angle(radians: atan2(p1.y - center.y, p1.x - center.x))
                                    let endAngle = Angle(radians: atan2(p2.y - center.y, p2.x - center.x))

                                    path.move(to: p1)
                                    path.addArc(
                                        center: center,
                                        radius: abs(radius),
                                        startAngle: startAngle,
                                        endAngle: endAngle,
                                        clockwise: clockwise
                                    )
                                }
                            }
                        }
                    }

                    .stroke(Color.blue, lineWidth: AppConfig.LineView.lineWidth)

                    if let robotPos = lineStore.robotPosition {
                        let transformed = transformPoint(robotPos, in: geometry)
                        Circle()
                            .fill(Color.red)
                            .frame(width: AppConfig.LineView.robotPositionwidth, height: AppConfig.LineView.robotPositionheight)
                            .position(transformed)
                    }
                }

                // Индикатор тачпада
                if touchController.touchIndicatorVisible {
                    TouchIndicatorView(controller: touchController)
                }
            }
        }
    }
    
    
    func transformPoint(_ point: CGPoint, in geometry: GeometryProxy) -> CGPoint {
        guard let robot = lineStore.robotPosition else { return point }
        let screenCenter = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
        // Смещение, чтобы робот был в центре
        let dx = screenCenter.x - robot.x * scale
        let dy = screenCenter.y - robot.y * scale
        // Применение масштаба и ручного смещения offset
        return CGPoint(
            x: point.x * scale + dx + offset.width,
            y: point.y * scale + dy + offset.height
        )
    }

}

