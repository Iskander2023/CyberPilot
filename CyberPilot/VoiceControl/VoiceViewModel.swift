//
//  VoiceViewModel.swift
//  CyberPilot
//
//  Created by Aleksandr Chumakov on 2/07/25.
//
import SwiftUI
import Combine



final class VoiceViewModel: ObservableObject {
    private let voiceManager: VoiceService
    private var cancellables = Set<AnyCancellable>()
    var voiceControlExternallyDisabled: (() -> Void)?

    
    @Published var transcribedText: String = ""
    @Published var isListening: Bool = false
    @Published var isSpeaking: Bool = false
    

    init(voiceManager: VoiceService) {
        self.voiceManager = voiceManager
        bind()
    }

    private func bind() {
        voiceManager.$transcribedText
            .assign(to: \.transcribedText, on: self)
            .store(in: &cancellables)

        voiceManager.$isListening
            .assign(to: \.isListening, on: self)
            .store(in: &cancellables)

        voiceManager.$isSpeaking
            .assign(to: \.isSpeaking, on: self)
            .store(in: &cancellables)
        
        voiceManager.$voiceControlShouldStop
            .filter { $0 } // Только если true
            .sink { [weak self] _ in
                self?.voiceControlExternallyDisabled?()
            }
            .store(in: &cancellables)
    }

    
    func requestAuthorization() {
        voiceManager.requestAuthorization()
    }

    
    func startVoiceControl() {
        voiceManager.speak(text: AppConfig.VoiceControl.startVoiceMessage) {
            self.voiceManager.startVoiceControl()
        }
    }

    
    func stopVoiceControl() {
        voiceManager.speak(text: AppConfig.VoiceControl.stopVoiceMessage) {
            self.voiceManager.stopVoiceControl()
        }
    }

}

