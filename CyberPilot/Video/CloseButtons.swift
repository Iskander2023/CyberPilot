//
//  CloseButtons.swift
//  CyberPilot
//
//  Created by Aleksandr Chumakov on 20/05/25.
//

import SwiftUI


struct CloseButton: View {
    var action: () -> Void
    
    var body: some View {
        VStack {
            HStack {
                Button(action: action) {
                    Text("Закрыть")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.black.opacity(0.5))
                        .cornerRadius(8)
                }
                .padding(.top, 16)
                .padding(.leading, 16)
                
                Spacer()
            }
            Spacer()
        }
    }
}
