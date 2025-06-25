//
//  BorderPointsView.swift
//  CyberPilot
//
//  Created by Aleksandr Chumakov on 5/06/25.
//

import SwiftUI


struct PointsView: View {
    let first: CGPoint?
    let second: CGPoint?

    var body: some View {
        ZStack {
            if let point = first {
                Circle()
                    .fill(Color.red)
                    .frame(width: AppConfig.PointSize.pointWidth, height: AppConfig.PointSize.pointHeight)
                    .position(point)
                    .allowsHitTesting(false)
            }
            if let point = second {
                Circle()
                    .fill(Color.blue)
                    .frame(width: AppConfig.PointSize.pointWidth, height: AppConfig.PointSize.pointHeight)
                    .position(point)
                    .allowsHitTesting(false)
            }
        }
    }
}
