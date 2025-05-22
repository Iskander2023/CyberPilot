//
//  MagnificationModifier.swift
//  CyberPilot
//
//  Created by Aleksandr Chumakov on 22/05/25.
//

import SwiftUI


extension View {
    func withMagnification() -> some View {
        modifier(MagnificationModifier())
    }
}


private struct MagnificationModifier: ViewModifier {
    @State private var currentScale: CGFloat = 1.0
    @State private var accumulatedScale: CGFloat = 1.0
    @EnvironmentObject private var controller: TouchController
    
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(currentScale * accumulatedScale)
            .gesture(
                MagnificationGesture()
                    .onChanged { value in
                        currentScale = value
                        controller.resetTouchPad()
                    }
                    .onEnded { value in
                        accumulatedScale *= value
                        currentScale = 1.0
                        controller.resetTouchPad()
                    }
            )
    }
}
