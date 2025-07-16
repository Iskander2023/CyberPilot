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

/// Сервис для голосового управления устройством.
/// Отвечает за распознавание речи, синтез речи и отправку команд.
final class VoiceService: NSObject, ObservableObject {
    /// Распознанный текст речи.
    @Published var transcribedText: String = ""
    /// Флаг, указывающий, что сейчас ведётся прослушивание.
    @Published var isListening: Bool = false
    /// Флаг, указывающий, что устройство произносит текст.
    @Published var isSpeaking: Bool = false
    /// Флаг, узказывающий вью что г.у. прекратилось в случае когда г.у. было остановлено голосовой командой (не кнопкой).
    @Published var voiceControlShouldStop: Bool = false
    /// Устройство через которое передаются голосовые команды(по умолчанию телефон)
    @Published var deviceState: DeviceState = .phone
    /// отправка команд роботу через сокет
    let commandSender: CommandSender
    /// логер
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
            logger.warn("🔇 Аудиосессия прервана")
            stopVoiceControl()
            deviceState = .idle
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
    
    /// метод определяющий подключаемые/отключаемые устройства
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
            deviceState = .headphones
        case .oldDeviceUnavailable:
            logger.info("🔌 Аудиоустройство отключено")
            restartAudioSession()
            deviceState = .phone
        default:
            break
        }
    }
    
    /// перезапуск аудио сессии
    func restartAudioSession() {
        stopListening()
        settingAudioSession()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.startVoiceControl()
        }
    }
    
    /// таймер отключения голосового управления через 30 секунд
    func restartSilenceTimer() {
        silenceTimer?.invalidate()
        silenceTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: false) { [weak self] _ in
            self?.logger.info("⏹ Завершаем распознавание: тишина")
            self?.stopVoiceControl()
        }
    }
    
    /// метод проверки разрешений использования голосового ввода на устройстве при запуске голосового ввода
    func requestAuthorization() {
        self.restartSilenceTimer() //
        
        if speechRecognizer?.supportsOnDeviceRecognition == true {
            recognitionRequest?.requiresOnDeviceRecognition = true
            logger.debug("Используется локальное распознавание")
        } else {
            logger.debug("Локальное распознавание недоступно")
        }
        // проверка доступности русского языка
        self.speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: AppConfig.VoiceService.language))
            if speechRecognizer == nil {
                logger.warn("⛔️ Русский язык не поддерживается")
                return
            }
        // разрешение на использование распознавания речи от пользователя
        SFSpeechRecognizer.requestAuthorization { authStatus in
            DispatchQueue.main.async {
                switch authStatus {
                case .authorized:
                    self.logger.info("✅ Распознавание речи разрешено пользователем.")
                default:
                    self.logger.warn("⛔️ Распознавание речи не разрешено пользователем: \(authStatus)")
                }
            }
        }
        // проверка доступа к микрофону
        if #available(iOS 17.0, *) {
            AVAudioApplication.requestRecordPermission { granted in
                if !granted {
                    self.logger.warn("Доступ к микрофону запрещен")
                }
            }
        } else {
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                if !granted {
                    self.logger.warn("Доступ к микрофону запрещен")
                }
            }
        }
    }
    

    /// метод останавливающий  аудиодвижок
    func stopAudioEngine() {
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
    }
    
    
    /// метод выключения голосового управления
    func stopVoiceControl() {
        logger.info("🛑 Голосовой ввод выключен")
        deviceState = .idle
        stopListening()
        stopRepeatingCommand()
        voiceControlShouldStop = true
    }
    
    
    /// метод остановки голосового ввода
    func stopListening() {
        guard isListening else { return }
        stopAudioEngine()
        isListening = false
        recognitionRequest = nil
        recognitionTask = nil
        silenceTimer?.invalidate()
        silenceTimer = nil
    }
    
    
    /// метод настройки аудиосессии
    func settingAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord,
                                         mode: .voiceChat,
                                         options: [.duckOthers, .defaultToSpeaker, .allowBluetooth])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            logger.debug("✅ Аудиосессия настроена")
        } catch {
            logger.error("⛔️ Ошибка настройки аудиосессии: \(error.localizedDescription)")
            return
        }
    }
    
    
    /// метод запускающий аудиодвижок
    func startAudioEngine() {
        do {
            audioEngine.prepare()
            try audioEngine.start()
            logger.debug("✅ AudioEngine запущен, микрофон активен")
        } catch {
            logger.warn("⛔️ Ошибка запуска audioEngine: \(error.localizedDescription)")
            return
        }
    }

    
    
    /// метод запускающий голосовое управление
    func startVoiceControl() {
        logger.info("✅ Запущено голосовое управление")
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
                self.logger.warn("⛔️ Ошибка распознавания: \(error.localizedDescription)")
                self.stopListening()
                return
            }

            guard let result = result else { return }

            let text = result.bestTranscription.formattedString
            self.transcribedText = text
            
            let words = text.lowercased().components(separatedBy: " ").filter { !$0.isEmpty }
            let lastWord = words.suffix(3).joined(separator: " ")  // Анализируем последние 1–2 слова
            
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
    
    
    
    /// метод отправки системных команд роботу
    func commandSystem(from command: VoiceCommand?) {
        if let sys = command {
            switch sys {
            case .stopVoiceControl:
                self.stopVoiceControl()
            default:
                    break
            }
        }
    }
    
    /// метод выбора направления движения робота
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
    
    
    /// метод отправки команд управления движением роботу через сокет
    func handleVoiceCommand(with direction: [String: Bool]) {
        commandSender.moveForward(isPressed: direction["forward"] ?? false)
        commandSender.moveBackward(isPressed: direction["backward"] ?? false)
        commandSender.turnLeft(isPressed: direction["left"] ?? false)
        commandSender.turnRight(isPressed: direction["right"] ?? false)
    }
    
    
    /// метод запуска таймера спамящего последнюю распознаную команду
    func startRepeatingLastCommand() {
        stopRepeatingCommand() // Сначала останавливаем, если уже был запущен
        repeatCommandTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self = self, let direction = self.lastDirection else { return }
            self.handleVoiceCommand(with: direction)
            self.logger.debug("🔁 Повтор команды: \(direction)")
        }
    }

    /// метод останавливки таймера
    func stopRepeatingCommand() {
        self.logger.debug("✅ Таймер остановлен")
        repeatCommandTimer?.invalidate()
        repeatCommandTimer = nil
    }
    
    
    
    /// метод озвучки текста
    func speak(text: String, language: String = AppConfig.VoiceService.language, rate: Float = 0.5, completion: (() -> Void)? = nil) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: language)
        utterance.rate = rate
        synthesizer.delegate = self
        speechCompletion = completion
        synthesizer.speak(utterance)
    }
    
    
    /// замыкание голосовой озвучки
    private var speechCompletion: (() -> Void)?

}

// AVSpeechSynthesizerDelegate
extension VoiceService: AVSpeechSynthesizerDelegate {
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        logger.debug("⛔️ Озвучка закончена: \(utterance.speechString)")
        DispatchQueue.main.async {
            self.isSpeaking = false
            self.speechCompletion?()
            self.speechCompletion = nil
        }
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        logger.debug("🗣 Начало озвучки: \(utterance.speechString)")
        DispatchQueue.main.async {
               self.isSpeaking = true
           }
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        logger.debug("⛔️ Озвучка отменена: \(utterance.speechString)")
    }
}
