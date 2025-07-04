//
//  VoiceControlView.swift
//  CyberPilot
//
//  Created by Aleksandr Chumakov on 1/07/25.
//

import SwiftUI

struct VoiceControlView: View {
    @EnvironmentObject var viewModel: VoiceViewModel


    var body: some View {
        VStack(spacing: 20) {
            Text("Команда: \(viewModel.transcribedText)")
                .font(.title2)
                .padding()

            if viewModel.isListening {
                Text("🎙 Слушаю...")
                    .foregroundColor(.green)
            }

            HStack {
                Button("🎤 Начать запись") {
                    viewModel.startVoiceControl()
                }

                Button("⛔️ Стоп") {
                    viewModel.stopVoiceControl()
                }
            }

            Button("🗣 Проговорить") {
                viewModel.speak(text: viewModel.transcribedText)
            }
        }
        .padding()
        .onAppear {
            viewModel.requestAuthorization()
        }
    }
}





