//
//  VoiceViewModel.swift
//  CyberPilot
//
//  Created by Aleksandr Chumakov on 2/07/25.
//
import SwiftUI
import Combine



final class VoiceViewModel: ObservableObject {
    private let voiceService: VoiceService
    private var cancellables = Set<AnyCancellable>()
    var voiceControlExternallyDisabled: (() -> Void)?
    
    @Published var state: DeviceState = .idle
    @Published var transcribedText: String = ""
    @Published var isListening: Bool = false
    @Published var isSpeaking: Bool = false
    
    var currentIcon: String {
        if !isListening {
            return AppConfig.VoiceControlButton.defaultIcon
        } else if state == .headphones {
            return AppConfig.VoiceControlButton.headphonesIcon
        } else {
            return AppConfig.VoiceControlButton.phoneIcon
        }
    }

    

    init(voiceManager: VoiceService) {
        self.voiceService = voiceManager
        bind()
    }

    private func bind() {
        voiceService.$transcribedText
            .assign(to: \.transcribedText, on: self)
            .store(in: &cancellables)

        voiceService.$isListening
            .assign(to: \.isListening, on: self)
            .store(in: &cancellables)

        voiceService.$isSpeaking
            .assign(to: \.isSpeaking, on: self)
            .store(in: &cancellables)
        
        voiceService.$voiceControlShouldStop
            .filter { $0 } // Только если true
            .sink { [weak self] _ in
                self?.voiceControlExternallyDisabled?()
            }
            .store(in: &cancellables)
        
        voiceService.$deviceState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newState in
                self?.state = newState
            }
            .store(in: &cancellables)
    }

    
    func requestAuthorization() {
        voiceService.requestAuthorization()
    }

    
    func startVoiceControl() {
        voiceService.speak(text: AppConfig.VoiceControl.startVoiceMessage) {
            self.voiceService.startVoiceControl()
        }
    }

    
    func stopVoiceControl() {
        voiceService.speak(text: AppConfig.VoiceControl.stopVoiceMessage) {
            self.voiceService.stopVoiceControl()
        }
    }

}

