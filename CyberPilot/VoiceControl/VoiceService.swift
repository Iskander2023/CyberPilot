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
    private var clearTimer: Timer?
    @Published var transcribedText: String = ""
    @Published var isListening: Bool = false
    @Published var isSpeaking: Bool = false


    private var speechRecognizer: SFSpeechRecognizer?
    private let audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let synthesizer = AVSpeechSynthesizer()
    
    var silenceTimer: Timer?
    

    init(commandSender: CommandSender) {
            self.commandSender = commandSender
            super.init()
            NotificationCenter.default.addObserver(
                    self,
                    selector: #selector(handleAudioSessionInterruption),
                    name: AVAudioSession.interruptionNotification,
                    object: nil
                )
        }
    
    
    @objc private func handleAudioSessionInterruption(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }

        if type == .began {
            logger.info("🔇 Аудиосессия прервана")
            stopListening()
        }
    }

    
    func restartSilenceTimer() {
        silenceTimer?.invalidate()
        silenceTimer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: false) { [weak self] _ in
            self?.logger.info("⏹ Завершаем распознавание: тишина")
            self?.stopListening()
        }
    }
    
    func requestAuthorization() {
        
        if speechRecognizer?.supportsOnDeviceRecognition == true {
            recognitionRequest?.requiresOnDeviceRecognition = true
            logger.info("Используется локальное распознавание")
        } else {
            logger.info("Локальное распознавание недоступно")
        }
        // проверка доступности русского языка
        self.speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: AppConfig.VoiceService.language))
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
    
    
    // проверка голосов ru-RU - милена
    func checkVoices() {
        let voices = AVSpeechSynthesisVoice.speechVoices()
        print("Доступные голоса: \(voices)")
    }
    
    
    // Останавка предыдущих задач аудиодвижка
    func stopAudioEngine() {
        audioEngine.stop()
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        do {
            try AVAudioSession.sharedInstance().setActive(false)
        } catch {
            logger.info("⛔️ Ошибка деактивации аудиосессии: \(error.localizedDescription)")
        }
    }
    
    
    // Настройка аудиосессии
    func settingAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord,
                                         mode: .voiceChat,
                                         options: [.duckOthers, .defaultToSpeaker, .allowBluetooth])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
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
            logger.info("⛔️ Распознавание речи для \(AppConfig.VoiceService.language) недоступно")
            return
        }
        guard !audioEngine.isRunning else {
            logger.info("⚠️ Распознавание уже запущено")
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
        
        
        //let inputFormat = inputNode.outputFormat(forBus: 0) // для тестов в эмуляторе
        
        // для телефона
        let sampleRate = AVAudioSession.sharedInstance().sampleRate
        let inputFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32,
                                        sampleRate: sampleRate,
                                        channels: 1,
                                        interleaved: false)!
        
        
        logger.info("Формат аудио: sampleRate=\(inputFormat.sampleRate), channels=\(inputFormat.channelCount)")
        inputNode.installTap(onBus: 0, bufferSize: 2048, format: inputFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }
        startAudioEngine()
        // Запускаем распознавание и записываем текст в буфер
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }

            if let error = error {
                self.logger.info("⛔️ Ошибка распознавания: \(error.localizedDescription)")
                self.stopListening()
                return
            }

            guard let result = result else { return }

            let text = result.bestTranscription.formattedString
            self.transcribedText = text
            self.restartSilenceTimer()

            let words = text.lowercased().components(separatedBy: " ").filter { !$0.isEmpty }
            //let lastWords = words.suffix(2).joined(separator: " ")  // Анализируем последние 1–2 слова
            let lastWord = words.last ?? "" // последнее слово

            if let voiceCommand = VoiceCommand.parse(from: lastWord) {
                let direction = self.commandDirection(from: voiceCommand)
                self.handleVoiceCommand(with: direction)
                self.logger.info("✅ Команда: \(direction)")
                self.logger.info("📢 Распознано: \(lastWord)")
                self.transcribedText = ""
            } else {
                self.logger.info("⚠️ Неизвестная команда: \(lastWord)")
            }

            if result.isFinal {
                self.logger.info("⏹ Финальный результат")
                self.stopListening()
            }
        }
    }
    
    func commandDirection(from command: VoiceCommand?) -> [String: Bool] {
        var flags = [
            "forward": false,
            "backward": false,
            "left": false,
            "right": false
        ]
        if let cmd = command {
            switch cmd {
            case .forward:
                flags["forward"] = true
            case .backward:
                flags["backward"] = true
            case .left:
                flags["left"] = true
            case .right:
                flags["right"] = true
            case .forwardLeft:
                flags["forward"] = true
                flags["left"] = true
            case .forwardRight:
                flags["forward"] = true
                flags["right"] = true
            case .stop:
                break
            }
        }

        return flags
    }


    
    func handleVoiceCommand(with direction: [String: Bool]) {
        commandSender.moveForward(isPressed: direction["forward"] ?? false)
        commandSender.moveBackward(isPressed: direction["backward"] ?? false)
        commandSender.turnLeft(isPressed: direction["left"] ?? false)
        commandSender.turnRight(isPressed: direction["right"] ?? false)
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
    func speak(text: String, language: String = AppConfig.VoiceService.language, rate: Float = 0.5) {
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
