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
                .stroke(AppConfig.TouchIndicator.color.opacity(AppConfig.TouchIndicator.opacity), lineWidth: AppConfig.TouchIndicator.lineWidth)
                .background(Circle().fill(Color.white.opacity(AppConfig.TouchIndicator.backgroundColorOpacity)))
                .frame(width: controller.touchIndicatorSize, height: controller.touchIndicatorSize)
                .position(controller.touchIndicatorPosition)
                .transition(.opacity)

            DirectionArrowView(
                arrowLength: controller.arrowLength,
                currentAngle: controller.currentAngle,
                touchIndicatorSize: controller.touchIndicatorSize,
                position: controller.touchIndicatorPosition,
                arrowColor: AppConfig.TouchIndicator.color,
                arrowOpacity: AppConfig.TouchIndicator.opacity
            )

            DirectionLabels(
                touchIndicatorSize: controller.touchIndicatorSize,
                position: controller.touchIndicatorPosition,
                labelsColor: AppConfig.TouchIndicator.color,
                labelsOpasity: AppConfig.TouchIndicator.opacity
            )
        }
    }
}

