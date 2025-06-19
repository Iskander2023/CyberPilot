//
//  BorderDrawingView.swift
//  CyberPilot
//
//  Created by Aleksandr Chumakov on 17/06/25.
//

import SwiftUI


struct BorderDrawingView: View {
    var firstTouch: CGPoint?
    var currentDragLocation: CGPoint?
    
    var body: some View {
        if let start = firstTouch, let current = currentDragLocation {
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
