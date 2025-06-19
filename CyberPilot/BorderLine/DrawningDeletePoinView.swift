//
//  DrawningDeletePoinView.swift
//  CyberPilot
//
//  Created by Aleksandr Chumakov on 19/06/25.
//

import SwiftUI


struct DrawningDeletePointView: View {

    var isDeleteBorder: Bool
    var touch: CGPoint?
    
    var body: some View {
        if isDeleteBorder {
            DeletePointView(
                touch: touch
            )
            .allowsHitTesting(false)
        }
    }
}
