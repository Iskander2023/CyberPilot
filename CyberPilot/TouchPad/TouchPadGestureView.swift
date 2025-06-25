//
//  TouchPadGestureView.swift
//  CyberPilot
//
//  Created by Aleksandr Chumakov on 20/05/25.
//
import SwiftUI


struct TouchPadGestureView: View {
    @EnvironmentObject private var controller: TouchController

    var body: some View {
        GeometryReader { geometry in
            Color.clear
                .contentShape(Rectangle())
                .simultaneousGesture(
                    DragGesture(minimumDistance: AppConfig.TouchPadGesture.minimumDistance)
                        .onChanged { value in
                            controller.handleTouchChanged(value)
                            controller.updateAnchorPoint(from: value.location, in: geometry.size)
                        }
                        .onEnded { _ in
                            controller.resetTouchPad()
                        }
                )
        }
    }
}



