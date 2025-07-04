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
                Image(systemName: AppConfig.PerspectiveButton.systemName)
                    .font(.system(size: AppConfig.PerspectiveButton.ikonSize))
                    .foregroundColor(AppConfig.PerspectiveButton.foreground)
            }
            .padding(.top, AppConfig.PerspectiveButton.paddingTop)
            .padding(.trailing, AppConfig.PerspectiveButton.paddingLeading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
    }
    
    private func changeVisiblePerspective() {
        withAnimation(.easeInOut(duration: 0.3)) {
            showPerspective.toggle()
        }
        
    }
}
