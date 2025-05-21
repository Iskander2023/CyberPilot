//
//  TouchIndicatorView.swift
//  CyberPilot
//
//  Created by Aleksandr Chumakov on 20/05/25.
//
import SwiftUI


struct TouchIndicatorView: View {
    @ObservedObject var controller: TouchController

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.blue.opacity(0.5), lineWidth: 2)
                .background(Circle().fill(Color.white.opacity(0.05)))
                .frame(width: controller.touchIndicatorSize, height: controller.touchIndicatorSize)
                .position(controller.touchIndicatorPosition)
                .transition(.opacity)

            DirectionArrow(
                arrowLength: controller.arrowLength,
                currentAngle: controller.currentAngle,
                touchIndicatorSize: controller.touchIndicatorSize,
                position: controller.touchIndicatorPosition
            )

            DirectionLabels(
                touchIndicatorSize: controller.touchIndicatorSize,
                position: controller.touchIndicatorPosition
            )
        }
    }
}

