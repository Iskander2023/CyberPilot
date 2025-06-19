//
//  BorderPointsDrawningView.swift
//  CyberPilot
//
//  Created by Aleksandr Chumakov on 18/06/25.
//

import SwiftUI


struct DrawningPointsView: View {
    var firstTouch: CGPoint?
    var currentDragLocation: CGPoint?
    
    var body: some View {
            PointsView(
                first: firstTouch,
                second: currentDragLocation
            )
            .allowsHitTesting(false)
    }
}
