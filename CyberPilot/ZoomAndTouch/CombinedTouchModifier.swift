//
//  CombinedTouchModifier.swift
//  CyberPilot
//
//  Created by Aleksandr Chumakov on 22/05/25.
//
import SwiftUI
import UIKit

struct CombinedTouchModifier: ViewModifier {
    let minScale: CGFloat
    let maxScale: CGFloat
    
    @State private var currentScale: CGFloat = 1.0
    @State private var accumulatedScale: CGFloat = 1.0
    @State private var zoomAnchor: UnitPoint = .center
    @State private var isPinching: Bool = false
    @State private var touchCount: Int = 0
    
    @EnvironmentObject private var controller: TouchController
    
    func body(content: Content) -> some View {
        content
            .overlay(
                PinchZoomView(
                    scale: $currentScale,
                    anchor: $zoomAnchor,
                    isPinching: $isPinching,
                    touchCount: $touchCount
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            )
            .scaleEffect(
                min(max(accumulatedScale * currentScale, minScale), maxScale),
                anchor: zoomAnchor
            )
            .animation(.interactiveSpring(), value: currentScale)
            .simultaneousGesture(
                DragGesture(minimumDistance: 5)
                    .onChanged { value in
                        guard !isPinching, touchCount < 2 else { return }
                        controller.handleTouchChanged(value)
                    }
                    .onEnded { _ in
                        guard !isPinching, touchCount < 2 else { return }
                        controller.resetTouchPad()
                    }
            )
            .onChange(of: isPinching) {
                if !isPinching {
                    accumulatedScale = min(max(accumulatedScale * currentScale, minScale), maxScale)
                    currentScale = 1.0
                    controller.resetTouchPad()
                    controller.touchIndicatorVisible = false
                }
            }
    }
}


