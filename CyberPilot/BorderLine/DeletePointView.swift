//
//  BorderDeletePointView.swift
//  CyberPilot
//
//  Created by Aleksandr Chumakov on 19/06/25.
//

import SwiftUI


struct DeletePointView: View {
    let touch: CGPoint?
    
    var body: some View {
        ZStack {
            if let point = touch {
                Circle()
                    .fill(Color.red)
                    .frame(width: 10, height: 10)
                    .position(point)
                    .allowsHitTesting(false)
            }
        }
    }
}
