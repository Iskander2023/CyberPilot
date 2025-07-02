//
//  VoiceControlManager.swift
//  CyberPilot
//
//  Created by Aleksandr Chumakov on 1/07/25.
//

import Foundation
import AVFoundation
import Speech
import Combine

final class VoiceService: NSObject, ObservableObject {
    let commandSender: CommandSender
    let logger = CustomLogger(logLevel: .info, includeMetadata: false)
    @Published var transcribedText: String = ""
    @Published var isListening: Bool = false
    @Published var isSpeaking: Bool = false


    private var speechRecognizer: SFSpeechRecognizer?
    private let audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let synthesizer = AVSpeechSynthesizer()
    private var cancellables = Set<AnyCancellable>()
    

    init(commandSender: CommandSender) {
            self.commandSender = commandSender
            super.init()
        }
    
    func requestAuthorization() {
        // проверка доступности русского языка
        self.speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "ru-RU"))
            if speechRecognizer == nil {
                logger.info("⛔️ Русский язык не поддерживается")
                return
            }
        // разрешение на использование распознавания речи от пользователя
        SFSpeechRecognizer.requestAuthorization { authStatus in
            DispatchQueue.main.async {
                switch authStatus {
                case .authorized:
                    self.logger.info("✅ Распознавание речи разрешено.")
                default:
                    self.logger.info("⛔️ Распознавание речи не разрешено: \(authStatus)")
                }
            }
        }
        // проверка доступа к микрофону
        if #available(iOS 17.0, *) {
            AVAudioApplication.requestRecordPermission { granted in
                if !granted {
                    self.logger.info("Доступ к микрофону запрещен")
                }
            }
        } else {
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                if !granted {
                    self.logger.info("Доступ к микрофону запрещен")
                }
            }
        }
    }
    
    
    // Останавка предыдущих задач аудиодвижка
    func stopAudioEngine() {
        audioEngine.stop()
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
    }
    
    
    // Настройка аудиосессии
    func settingAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
            try audioSession.setActive(true)
            logger.info("✅ Аудиосессия настроена")
        } catch {
            logger.info("⛔️ Ошибка настройки аудиосессии: \(error.localizedDescription)")
            return
        }
    }
    
    
    // Запускаем аудиодвижок
    func startAudioEngine() {
        do {
            audioEngine.prepare()
            try audioEngine.start()
            logger.info("✅ AudioEngine запущен, микрофон активен")
        } catch {
            logger.info("⛔️ Ошибка запуска audioEngine: \(error.localizedDescription)")
            return
        }
    }

    
    func startListening() {
        // Проверяем, что распознаватель речи доступен
        guard let speechRecognizer = speechRecognizer else {
            logger.info("⛔️ Распознавание речи для ru-RU недоступно")
            return
        }
        isListening = true
        stopAudioEngine()
        settingAudioSession()
        // Создаем новый запрос на распознавание
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            logger.info("⛔️ Не удалось создать recognitionRequest")
            return
        }
        // Настройка микрофонного входа
        let inputNode = audioEngine.inputNode
        inputNode.removeTap(onBus: 0) // Удаляем старый tap, если был
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 2048, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }
        startAudioEngine()
        // Запускаем распознавание и записываем текст в буфер
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            if let error = error {
                self?.logger.info("⛔️ Ошибка распознавания: \(error.localizedDescription)")
                return
            }
            guard let result = result else { return }
            let text = result.bestTranscription.formattedString
                DispatchQueue.main.async {
                    self?.transcribedText = text
                }
                self?.logger.info("Результат: \(text)")
            }
        }


    // остановка голосового управления
    func stopListening() {
        stopAudioEngine()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest = nil
        recognitionTask = nil
        isListening = false
    }

    
    // метод воспроизведения текста в голосовую речь
    func speak(text: String, language: String = "ru-RU", rate: Float = 0.5) {
        stopListening()

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: language)
        utterance.rate = rate

        isSpeaking = true
        synthesizer.delegate = self
        synthesizer.speak(utterance)
    }

    
    func stopSpeaking() {
        synthesizer.stopSpeaking(at: .immediate)
        isSpeaking = false
    }
}

// AVSpeechSynthesizerDelegate
extension VoiceService: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isSpeaking = false
        }
    }
}
