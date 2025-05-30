//
//  TouchIndicatorView.swift
//  CyberPilot
//
//  Created by Aleksandr Chumakov on 20/05/25.
//
import SwiftUI


struct TouchIndicatorView: View {
    @ObservedObject var controller: TouchController
    let generalColor: Color = .blue
    let generalOpacity: Double = 0.2

    var body: some View {
        ZStack {
            Circle()
                .stroke(generalColor.opacity(generalOpacity), lineWidth: 2)
                .background(Circle().fill(Color.white.opacity(0.01)))
                .frame(width: controller.touchIndicatorSize, height: controller.touchIndicatorSize)
                .position(controller.touchIndicatorPosition)
                .transition(.opacity)

            DirectionArrowView(
                arrowLength: controller.arrowLength,
                currentAngle: controller.currentAngle,
                touchIndicatorSize: controller.touchIndicatorSize,
                position: controller.touchIndicatorPosition,
                arrowColor: generalColor,
                arrowOpacity: generalOpacity
            )

            DirectionLabels(
                touchIndicatorSize: controller.touchIndicatorSize,
                position: controller.touchIndicatorPosition,
                labelsColor: generalColor,
                labelsOpasity: generalOpacity
            )
        }
    }
}

