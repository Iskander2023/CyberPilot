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
    @Published var transcribedText: String = ""
    @Published var isListening: Bool = false
    @Published var isSpeaking: Bool = false
    @Published var voiceControlShouldStop: Bool = false

    
    let commandSender: CommandSender
    let logger = CustomLogger(logLevel: .info, includeMetadata: false)

    private var speechRecognizer: SFSpeechRecognizer?
    private let audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let synthesizer = AVSpeechSynthesizer()
    private var silenceTimer: Timer?
    private var lastProcessedCommandText: String = ""
    private var repeatCommandTimer: Timer?
    private var lastDirection: [String: Bool]?
    private var isVoiceControlStopped = false
    
    init(commandSender: CommandSender) {
            self.commandSender = commandSender
            super.init()
            // уведомление о входящем звонке
            NotificationCenter.default.addObserver(
                    self,
                    selector: #selector(handleAudioSessionInterruption),
                    name: AVAudioSession.interruptionNotification,
                    object: nil
                )
            // уведомление о смене источника
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleRouteChange),
                name: AVAudioSession.routeChangeNotification,
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
        // возобновление голосового режима после звонка
//        if type == .ended,
//           let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
//            let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
//            if options.contains(.shouldResume) {
//                try? startListening()
//            }
//        }

    }
    
    
    @objc private func handleRouteChange(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else {
            return
        }
        switch reason {
        case .newDeviceAvailable:
            logger.info("🎧 Подключено новое аудиоустройство")
            restartAudioSession()
        case .oldDeviceUnavailable:
            logger.info("🔌 Аудиоустройство отключено")
            restartAudioSession()
        default:
            break
        }
    }
    
    // перезапуск аудио сессии
    func restartAudioSession() {
        stopListening()
        settingAudioSession()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.startVoiceControl()
        }
    }
    
    // таймер отключения голосового управления через 30 секунд
    func restartSilenceTimer() {
        silenceTimer?.invalidate()
        silenceTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: false) { [weak self] _ in
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
    
    
    // проверка голосов ru-RU - милена текущий
    func checkVoices() {
        let voices = AVSpeechSynthesisVoice.speechVoices()
        print("Доступные голоса: \(voices)")
    }
    
    
    // Останавка предыдущих задач аудиодвижка
    func stopAudioEngine() {
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
    }
    
    
    // деактивация аудиодвижка
    func deactivateAudioEngine() {
        do {
            // Добавьте проверку активности сессии перед деактивацией
            if AVAudioSession.sharedInstance().isOtherAudioPlaying {
                try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
                logger.info("✅ Аудиосессия успешно деактивирована")
            }
        } catch {
            logger.error("🛑 Ошибка при деактивации аудиосессии: \(error.localizedDescription)")
            try? AVAudioSession.sharedInstance().setActive(false, options: [])
        }
    }
    
    
    // деактивация голосового управления
    func stopVoiceControl() {
        logger.info("🛑 Вызван stopVoiceControl")
        stopListening()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.deactivateAudioEngine()
            }
        stopRepeatingCommand()
        voiceControlShouldStop = true
    }
    
    
    // остановка голосового управления
    func stopListening() {
        guard isListening else { return }
        logger.info("🛑 stopListening")
        stopAudioEngine()
        isListening = false
        recognitionRequest = nil
        recognitionTask = nil
        silenceTimer?.invalidate()
        silenceTimer = nil
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

    
    func startVoiceControl() {
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
        let inputFormat = inputNode.inputFormat(forBus: 0)
        logger.info("📢 Формат аудио: sampleRate=\(inputFormat.sampleRate), channels=\(inputFormat.channelCount)")
        inputNode.installTap(onBus: 0, bufferSize: 2048, format: inputFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }
        
        startAudioEngine()
        
        // Запускаем распознавание и записываем текст в буфер
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }

            if let error = error {
                self.logger.info("⛔️ Ошибка распознавания: \(error.localizedDescription)")
                //self.stopListening()
                return
            }

            guard let result = result else { return }

            let text = result.bestTranscription.formattedString
            self.transcribedText = text
            self.restartSilenceTimer()

            
            let words = text.lowercased().components(separatedBy: " ").filter { !$0.isEmpty }
            let lastWord = words.suffix(3).joined(separator: " ")  // Анализируем последние 1–2 слова
//            let lastWord = words.last ?? "" // последнее слово
            
            guard lastWord != self.lastProcessedCommandText else { return }
            
            if let voiceCommand = VoiceCommand.parse(from: lastWord) {
                switch voiceCommand.category {
                case .movement:
                    let direction = self.commandDirection(from: voiceCommand)
                    self.lastDirection = direction
                    self.startRepeatingLastCommand() // отправка последней команды
                    self.logger.info("✅ Команда: \(direction)")
                    self.logger.info("📢 Распознано: \(lastWord)")
                    self.transcribedText = ""
                    self.lastProcessedCommandText = lastWord // ✅ Запоминаем
                case .system:
                    self.commandSystem(from: voiceCommand)// вариант отправки одной команды без спама
                    self.transcribedText = ""
                }
                
            } else {
                self.logger.info("⚠️ Неизвестная команда: \(lastWord)")
            }

            if result.isFinal {
                self.logger.info("⏹ Финальный результат")
                self.lastDirection = nil
            }
        }
    }
    
    // команды управления роботом
    func commandSystem(from command: VoiceCommand?) {
        if let sys = command {
            switch sys {
            case .stopVoiceControl:
//                speak(text: AppConfig.VoiceControl.stopVoiceMessage) {
//                    self.stopVoiceControl()
//                }
                self.stopVoiceControl()
            default:
                    break
            }
        }
    }
    
    // команды управления движением робота
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
                self.lastDirection = nil
                stopRepeatingCommand()
            default:
                    break
            }
        }

        return flags
    }
    
    
    // отправка команд управления роботу через сокет
    func handleVoiceCommand(with direction: [String: Bool]) {
        commandSender.moveForward(isPressed: direction["forward"] ?? false)
        commandSender.moveBackward(isPressed: direction["backward"] ?? false)
        commandSender.turnLeft(isPressed: direction["left"] ?? false)
        commandSender.turnRight(isPressed: direction["right"] ?? false)
    }
    
    
    // Запускаем таймер после распознавания команды
    func startRepeatingLastCommand() {
        stopRepeatingCommand() // Сначала останавливаем, если уже был запущен
        repeatCommandTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self = self, let direction = self.lastDirection else { return }
            self.handleVoiceCommand(with: direction)
            self.logger.info("🔁 Повтор команды: \(direction)")
        }
    }

    // Останавливаем таймер
    func stopRepeatingCommand() {
        self.logger.info("✅ Таймер остановлен")
        repeatCommandTimer?.invalidate()
        repeatCommandTimer = nil
    }
    
    
//    func stopSpeaking() {
//        synthesizer.stopSpeaking(at: .immediate)
//        isSpeaking = false
//    }
    
    
    // метод озвучки
    func speak(text: String, language: String = AppConfig.VoiceService.language, rate: Float = 0.5, completion: (() -> Void)? = nil) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: language)
        utterance.rate = rate
        //stopAudioEngine()
        isSpeaking = true
        synthesizer.delegate = self
        speechCompletion = completion
        synthesizer.speak(utterance)
    }

    private var speechCompletion: (() -> Void)?

}

// AVSpeechSynthesizerDelegate
extension VoiceService: AVSpeechSynthesizerDelegate {
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isSpeaking = false
            self.speechCompletion?()
            self.speechCompletion = nil
        }
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        logger.info("🗣 Начало озвучки: \(utterance.speechString)")
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        logger.info("⛔️ Озвучка отменена: \(utterance.speechString)")
    }
}
