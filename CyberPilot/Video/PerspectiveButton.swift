//
//  PerspectiveButton.swift
//  CyberPilot
//
//  Created by Aleksandr Chumakov on 26/06/25.
//

import SwiftUI



struct PerspectiveButton: View {
    @Binding var showPerspective: Bool
    
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            Button(action: changeVisiblePerspective) {
                Image(systemName: AppConfig.VideoView.systemName)
                    .font(.system(size: AppConfig.VideoView.ikonSize))
                    .foregroundColor(AppConfig.VideoView.foreground)
            }
            .padding(.top, AppConfig.VideoView.paddingTop)
            .padding(.trailing, AppConfig.VideoView.paddingLeading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
    }
    
    private func changeVisiblePerspective() {
        withAnimation(.easeInOut(duration: 0.3)) {
            showPerspective.toggle()
        }
        
    }
}
