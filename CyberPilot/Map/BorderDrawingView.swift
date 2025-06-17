//
//  BorderDrawingView.swift
//  CyberPilot
//
//  Created by Admin on 17/06/25.
//

import SwiftUI


struct BorderDrawingView: View {
    var isAddingBorder: Bool
    var firstTouch: CGPoint?
    var currentDragLocation: CGPoint?
    
    var body: some View {
        if isAddingBorder, let start = firstTouch, let current = currentDragLocation {
            BorderLineView(
                start: start,
                end: current,
                color: .red,
                lineWidth: 2,
                dash: [5]
            )
            .allowsHitTesting(false)
        }
    }
}
