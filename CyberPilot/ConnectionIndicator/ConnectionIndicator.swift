//
//  ConnectionIndicator.swift
//  CyberPilot
//
//  Created by Admin on 24/07/25.
//

import SwiftUI

struct ConnectionIndicator: View {
    
    
    var body: some View {
        HStack {
            Circle()
                .frame(width: AppConfig.SocketView.connectionIndicatorCircleWidth, height: AppConfig.SocketView.connectionIndicatorCircleHeight)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
        
        
    }
}



