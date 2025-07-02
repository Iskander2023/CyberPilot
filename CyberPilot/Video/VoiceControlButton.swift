//
//  VoiceControlButton.swift
//  CyberPilot
//
//  Created by Aleksandr Chumakov on 2/07/25.
//
import SwiftUI


struct VoiceControlButton: View {
    @EnvironmentObject var voiceViewModel: VoiceViewModel
    @State private var animateWaves = false
    @Binding var voiceControl: Bool

    var body: some View {
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: activateVoiceControl) {
                        Image(systemName: voiceViewModel.isListening ? "waveform.circle.fill" : "mic.circle")
                            .font(.system(size: AppConfig.VideoView.voiceButtonikonSize))
                            .foregroundColor(AppConfig.VideoView.foreground)
                            // Анимация пульсации, только если слушаем
                            .scaleEffect(voiceViewModel.isListening && animateWaves ? 1.2 : 1)
                            .animation(voiceViewModel.isListening ?
                                Animation.easeInOut(duration: 1).repeatForever(autoreverses: true)
                                : .default, value: animateWaves)
                    }
                    .padding(.bottom, AppConfig.VideoView.paddingBottom)
                    .padding(.trailing, AppConfig.VideoView.paddingTrailing)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onAppear {
                if voiceViewModel.isListening {
                    animateWaves = true
                }
                voiceViewModel.requestAuthorization()
            }
        }

        private func activateVoiceControl() {
            withAnimation(.easeInOut(duration: 0.3)) {
                voiceControl.toggle()
                if voiceControl {
                    voiceViewModel.startListening()
                } else {
                    voiceViewModel.stopListening()
                }
            }
        }
    }

