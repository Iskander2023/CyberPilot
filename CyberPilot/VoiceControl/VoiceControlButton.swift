//
//  VoiceControlButton.swift
//  CyberPilot
//
//  Created by Aleksandr Chumakov on 2/07/25.
//
import SwiftUI


struct VoiceControlButton: View {
    @EnvironmentObject var voiceViewModel: VoiceViewModel
    @Binding var voiceControl: Bool
    
    var body: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button(action: activateVoiceControl) {
                    Image(systemName: voiceViewModel.currentIcon)
                        .font(.system(size: AppConfig.VoiceControlButton.voiceIkonSize))
                        .foregroundColor(AppConfig.VoiceControlButton.foreground)
                }
                .padding(.bottom, AppConfig.VoiceControlButton.paddingBottom)
                .padding(.trailing, AppConfig.VoiceControlButton.paddingTrailing)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            voiceViewModel.requestAuthorization()
            voiceViewModel.voiceControlExternallyDisabled = {
                    voiceControl = false
                }
        }
        .disabled(voiceViewModel.isSpeaking)
    }
    
    private func activateVoiceControl() {
        voiceControl.toggle()
        if voiceControl {
            voiceViewModel.startVoiceControl()
        } else {
            voiceViewModel.stopVoiceControl()
        }
    }
}

