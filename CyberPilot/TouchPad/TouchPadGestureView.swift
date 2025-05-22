//
//  TouchPadGestureView.swift
//  CyberPilot
//
//  Created by Admin on 20/05/25.
//
import SwiftUI


struct TouchPadGestureView: View {
    @EnvironmentObject private var controller: TouchController
    
    var body: some View {
        Color.clear
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        controller.handleTouchChanged(value)
                    }
                    .onEnded { _ in
                        controller.resetTouchPad()
                    }
            )
    }
}

