//
//  DirectionArrow.swift
//  CyberPilot
//
//  Created by Aleksandr Chumakov on 20/05/25.
//
import SwiftUI

struct DirectionArrow: View {
    let arrowLength: CGFloat
    let currentAngle: CGFloat
    let touchIndicatorSize: CGFloat
    let position: CGPoint

    var body: some View {
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
        .position(position)
    }
}

