//
//  DirectionLabels.swift
//  CyberPilot
//
//  Created by Aleksandr Chumakov on 20/05/25.
//

import SwiftUI


struct DirectionLabels: View {
    let touchIndicatorSize: CGFloat
    let position: CGPoint
    let labelsColor: Color
    let labelsOpasity: Double

    var body: some View {
        ZStack {
            ForEach(0..<8) { i in
                let angle = Double(i) * .pi / 4 - .pi / 8
                let radius = touchIndicatorSize / 2 - 15
                let center = CGPoint(x: touchIndicatorSize / 2, y: touchIndicatorSize / 2)
                let x = center.x + radius * cos(angle)
                let y = center.y + radius * sin(angle)

                Circle()
                    .frame(width: 6, height: 6)
                    .foregroundColor(labelsColor.opacity(labelsOpasity))
                    .position(x: x, y: y)
            }
        }
        .frame(width: touchIndicatorSize, height: touchIndicatorSize)
        .position(position)
    }
}
