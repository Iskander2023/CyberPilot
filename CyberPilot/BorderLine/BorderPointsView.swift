//
//  BorderPointsView.swift
//  CyberPilot
//
//  Created by Aleksandr Chumakov on 5/06/25.
//

import SwiftUI


struct BorderPointsView: View {
    let first: CGPoint?
    let second: CGPoint?

    var body: some View {
        Group {
            if let point = first {
                Circle()
                    .fill(Color.red)
                    .frame(width: 10, height: 10)
                    .position(point)
                    .allowsHitTesting(false)
            }
            if let point = second {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 10, height: 10)
                    .position(point)
                    .allowsHitTesting(false)
            }
        }
    }
}
