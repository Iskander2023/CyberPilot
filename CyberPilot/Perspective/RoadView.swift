//
//  RoadView.swift
//  CyberPilot
//
//  Created by Aleksandr Chumakov on 27/04/25.
//
import SwiftUI


struct RoadView: View {
    @State private var roadWidth: CGFloat = 400
    @State private var lineHeight: CGFloat = 30
    @State private var segmentAngle: CGFloat = 0
    @State private var previousDegrees: CGFloat = 270
    
    var horizontalPixels: CGFloat
    var verticalPixels: CGFloat
    var angle: CGFloat
    var segmentsCount: Int
    

    var body: some View {
        VStack {
            Canvas { context, size in
                let perspective = Perspective(horizontalPixels: horizontalPixels, verticalPixels: verticalPixels)
                let bottom = perspective.bottomCentralPoint
                let segmentHeight = lineHeight * CGFloat(segmentsCount)
                let halfRoadWidth = roadWidth / 2
                var bottomPoints: [(CGFloat, CGFloat)] = [(-halfRoadWidth, bottom), (halfRoadWidth, bottom)]
                var upperPoints: [(CGFloat, CGFloat)] = []

                for i in 0..<segmentsCount {
                    upperPoints = getUpperPoints(
                        segmentHeight: segmentHeight,
                        segmentAngle: segmentAngle,
                        number: i,
                        bottomPoints: bottomPoints,
                        roadWidth: roadWidth
                    )
                    let points = [bottomPoints[0], upperPoints[0], upperPoints[1], bottomPoints[1]]
                    let projected = perspective.project(points: points)
                    var path = Path()
                    path.move(to: CGPoint(x: projected[0].0, y: size.height - projected[0].1))
                    for p in projected.dropFirst() {
                        path.addLine(to: CGPoint(x: p.0, y: size.height - p.1))
                    }
                    path.closeSubpath()
                    context.fill(path, with: .color(.clear.opacity(0.2)))
                    context.stroke(path, with: .color(.yellow), lineWidth: 2)
                    bottomPoints = upperPoints
                }
            }
            .frame(width: horizontalPixels, height: verticalPixels)
            .background(Color.clear)
            .onChange(of: angle) { _, newValue in
                updateAngle(angle: newValue)
            }
        }
    }
    
    
    func updateAngle(angle: CGFloat) {
        var degrees = angle * 180 / .pi
        degrees = normalizeDegrees(degrees)
        let delta = shortestAngleDifference(from: previousDegrees, to: degrees)
        var clampedDegrees = previousDegrees + delta
        clampedDegrees = min(max(clampedDegrees, 180), 360)
        previousDegrees = clampedDegrees
        let adjustedDegrees = clampedDegrees - 270
        self.segmentAngle = -(adjustedDegrees / CGFloat(segmentsCount)) * .pi / 180
    }

    
    func normalizeDegrees(_ degrees: CGFloat) -> CGFloat {
        var result = degrees.truncatingRemainder(dividingBy: 360)
        if result < 0 { result += 360 }
        return result
    }

    func shortestAngleDifference(from: CGFloat, to: CGFloat) -> CGFloat {
        var delta = (to - from).truncatingRemainder(dividingBy: 360)
        if delta < -180 { delta += 360 }
        if delta > 180 { delta -= 360 }
        return delta
    }

    func getUpperPoints(segmentHeight: CGFloat, segmentAngle: CGFloat, number: Int,
                        bottomPoints: [(CGFloat, CGFloat)], roadWidth: CGFloat) -> [(CGFloat, CGFloat)] {
        let halfRoadWidth = roadWidth / 2
        let halfAngle = segmentAngle * CGFloat(number) + segmentAngle / 2 + .pi / 2
        let angle0 = segmentAngle * CGFloat(number) + segmentAngle + .pi
        let angle2 = segmentAngle * CGFloat(number) + segmentAngle

        let x = (bottomPoints[0].0 + bottomPoints[1].0) / 2
        let y = (bottomPoints[0].1 + bottomPoints[1].1) / 2

        let x1 = cos(halfAngle) * segmentHeight + x
        let y1 = sin(halfAngle) * segmentHeight + y
        let x0 = cos(angle0) * halfRoadWidth + x1
        let y0 = sin(angle0) * halfRoadWidth + y1
        let x2 = cos(angle2) * halfRoadWidth + x1
        let y2 = sin(angle2) * halfRoadWidth + y1

        return [(x0, y0), (x2, y2)]
    }
}
