//
//  ChatView.swift
//  CyberPilot
//
//  Created by Aleksandr Chumakov on 16/07/25.
//

import SwiftUI


struct ChatButton: View {
    
    var body: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button(action: {
                    print("Chat button tapped")
                    }) {
                    Image(systemName: AppConfig.ChatButton.chatIcon)
                        .font(.system(size: AppConfig.ChatButton.voiceIkonSize))
                        .foregroundColor(AppConfig.ChatButton.foreground)
                }
                .padding(.bottom, AppConfig.ChatButton.paddingBottom)
                .padding(.trailing, AppConfig.ChatButton.paddingTrailing)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        
    }
}
