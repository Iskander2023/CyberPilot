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
    }

    func requestAuthorization() {
        voiceManager.requestAuthorization()
    }

    func startListening() {
        voiceManager.startListening()
    }

    func stopListening() {
        voiceManager.stopListening()
    }

    func speak(text: String) {
        voiceManager.speak(text: text)
    }

    func stopSpeaking() {
        voiceManager.stopSpeaking()
    }
}

