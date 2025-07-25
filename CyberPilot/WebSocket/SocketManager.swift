//
//  Socket.swift
//  Robot_Controller
//
//  Created by Aleksandr Chumakov on 18/03/25.
//
import Starscream
import Combine

class SocketManager: NSObject, WebSocketDelegate, ObservableObject {
    
    @Published var isConnected: Bool = false
    @Published var connectionError: String?
    @Published var lastMessage: [String: Any]?
    
    let receivedResponses = PassthroughSubject<String, Never>()
    let receivedMessages = PassthroughSubject<[String: Any], Never>()
    let ipResolvedPublisher = PassthroughSubject<String, Never>()
    let ipResolveErrorPublisher = PassthroughSubject<String?, Never>()

    var socket: WebSocket!
    var accessToken: String?
    var authService: AuthService
    var onMapArrayReceived: (([Int], Int) -> Void)?
    var onLineMessageReceived: (([[[Double]]], CGPoint) -> Void)?
    let logger = CustomLogger(logLevel: .debug, includeMetadata: false)
    
    private var refreshTimer: Timer?
    private let refreshMargin: TimeInterval = 30  // сек до окончания токена
    
    private var cancellables = Set<AnyCancellable>()
    private var connectCompletion: ((Bool) -> Void)?
    
    init(authService: AuthService) {
        self.authService = authService
        super.init()
        setupBindings()
    }
    
    
    private func setupBindings() {
        authService.$accessToken
            .sink { [weak self] newToken in
                self?.accessToken = newToken
            }
            .store(in: &cancellables)
    }
    
    
    // переподключение
    func attemptReconnect(after delay: TimeInterval = 2.0) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            self.logger.info("Попытка переподключения...")
            self.socket.connect()
        }
    }
    
    
    func connectSocket(urlString: String, timeout: TimeInterval = 5, completion: @escaping (Bool) -> Void) {
            guard !isConnected else {
                logger.info("Уже подключено.")
                completion(true)
                return
            }

            guard let url = URL(string: urlString) else {
                logger.info("Ошибка: неверный URL")
                completion(false)
                return
            }

            var request = URLRequest(url: url)
            request.timeoutInterval = timeout

            socket = WebSocket(request: request)
            socket.delegate = self
            self.connectCompletion = completion
            socket.connect()
        }
        
    
    func disconnectSocket() {
        if let socket = socket{
            socket.disconnect()
        }
        onLineMessageReceived = nil
    }
    
    
    func sendJSONCommand(_ data: [String: Any]) {
        guard let jsonData = try? JSONSerialization.data(withJSONObject: data, options: []),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            self.logger.info("Ошибка: не удалось закодировать JSON")
            return
        }
        self.logger.info("\(jsonString)")
        sendCommand(jsonString)
    }
    
    
    
    func sendCommand(_ command: String) {
        if isConnected {
            self.logger.debug("Отправка команды: \(command)")
            socket.write(string: command)
        } else {
            self.logger.debug("Ошибка отправки команды: \(command), соединение не установлено.")
            return
        }
    }
    
    
    private func handleChatMessage(_ data: Data) {
            if let jsonObject = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                self.receivedMessages.send(jsonObject)
            } else {
            logger.warn("Ошибка при парсинге chat-сообщения")
        }
    }

    
    private func handleTextMessage(_ message: String) {
        guard let data = message.data(using: .utf8) else {
            logger.info("Не удалось конвертировать сообщение в Data")
            return
        }
        do {
            let messageType = try JSONDecoder().decode(MessageType.self, from: data).type
            switch messageType {
                
            case "chat":
                handleChatMessage(data)
           
            case "map":
                handleMapMessage(data: data)
                
            case "line":
                handleLineMessage(data: data)
                
            default:
                logger.info("Получен неизвестный тип сообщения: \(messageType)")
                receivedResponses.send("Получен неизвестный тип сообщения")
            }
            
        } catch {
            logger.info("Ошибка при парсинге сообщения: \(error.localizedDescription)")
        }
    }
    
    
    private func handleMapMessage(data: Data) {
        do {
            let decodedMessage = try JSONDecoder().decode(MapMessage.self, from: data)
            onMapArrayReceived?(decodedMessage.data, decodedMessage.len)
        } catch {
            logger.error("❌ Ошибка декодирования MapMessage: \(error.localizedDescription)")
        }
    }

    
    private func handleLineMessage(data: Data) {
        do {
            let decodeMessage = try JSONDecoder().decode(SegmentMessage.self, from: data)
            let centerPoint = decodeMessage.center.cgPoint
            onLineMessageReceived?(decodeMessage.data, centerPoint)
        } catch {
            logger.info("Ошибка декодирования LineMessage: \(error.localizedDescription)")
        }
    }
    
    
    func handleConnected(headers: [String: String]) {
        isConnected = true
        connectionError = nil
        connectCompletion?(true)
        connectCompletion = nil
        startRefreshLoop()
        logger.info("Connection established. Headers: \(headers)")
    }
    
    
    func handleDisconnected(reason: String, code: UInt16) {
        isConnected = false
        connectCompletion?(false)
        connectCompletion = nil
        refreshTimer?.invalidate()
        refreshTimer = nil
        connectionError = "Disconnected: \(reason) (code \(code))"
        logger.info("Connection closed. Reason: \(reason), Код: \(code)")
    }
    
    
    func handleError(_ error: Error?) {
        if let error = error {
            connectionError = error.localizedDescription
            logger.info("Error WebSocket: \(error.localizedDescription)")
        }
    }
    
    func handleCancelled() {
        isConnected = false
        logger.info("Connection canceled.")
        connectCompletion?(false)
        connectCompletion = nil
        refreshTimer?.invalidate()
        refreshTimer = nil
        self.receivedResponses.send("Connection canceled.")
    }
    
    
    func handlePeerClosed() {
        isConnected = false
        logger.info("Connection closed")
        connectCompletion?(false)
        connectCompletion = nil
        refreshTimer?.invalidate()
        refreshTimer = nil
        self.receivedResponses.send("Connection closed.")
    }
    
    
    func didReceive(event: WebSocketEvent, client: WebSocketClient) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            switch event {
            case .connected(let headers):
                self.handleConnected(headers: headers)
            case .disconnected(let reason, let code):
                self.handleDisconnected(reason: reason, code: code)
            case .text(let message):
                self.handleTextMessage(message)
            case .binary(let data):
                self.logger.info("Received binary data: \(data)")
            case .pong(let pongData):
                self.logger.info("Received PONG: \(String(describing: pongData))")
            case .ping(let pingData):
                self.logger.info("Received PING: \(String(describing: pingData))")
            case .error(let error):
                self.handleError(error)
            case .viabilityChanged(let isViable):
                self.logger.info("Change in Vitality: \(isViable)")
            case .reconnectSuggested(let shouldReconnect):
                self.logger.info("Reconnection suggested: \(shouldReconnect)")
            case .cancelled:
                self.handleCancelled()
            case .peerClosed:
                self.handlePeerClosed()
            }
        }
    }
    
    
    /// получение exp
    func decodeExp(from jwt: String) -> TimeInterval? {
        let segments = jwt.split(separator: ".")
        guard segments.count == 3 else { return nil }

        var base64 = String(segments[1])
        let padding = 4 - base64.count % 4
        if padding < 4 {
            base64 += String(repeating: "=", count: padding)
        }

        guard let payloadData = Data(base64Encoded: base64),
              let json = try? JSONSerialization.jsonObject(with: payloadData, options: []),
              let payload = json as? [String: Any] else {
            return nil
        }
        if let exp = payload["exp"] as? TimeInterval {
            return exp
        } else if let expStr = payload["exp"] as? String,
                  let exp = TimeInterval(expStr) {
            return exp
        }

        return nil
    }

    
    
    func startRefreshLoop() {
        refreshTimer?.invalidate()

        refreshTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }

            guard let refreshToken = self.authService.refreshToken,
                  !refreshToken.isEmpty,
                  let exp = decodeExp(from: refreshToken) else {
                self.logger.error("❌ Некорректный или отсутствующий refresh token.")
                return
            }

            let now = Date().timeIntervalSince1970
            let ttl = exp - now
            self.logger.info("🕒 TTL refresh-токена: \(ttl) сек.")

            if ttl < self.refreshMargin {
                self.logger.info("⏳ Токен почти истёк, обновляем...")
                self.refreshAccessToken()
            }
        }
    }

    
    
    func refreshAccessToken() {
        guard let refreshToken = authService.refreshToken else {
            logger.error("❌ Refresh token отсутствует.")
            return
        }

        // Формируем URL
        guard let url = URL(string: "\(AppConfig.Addresses.baseUrl)/refresh") else {
            logger.error("❌ Неверный URL для обновления токена")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        logger.info("request: \(request)")

        let body: [String: String] = ["refresh_token": refreshToken]
        request.httpBody = try? JSONEncoder().encode(body)
        
        
        if let jsonData = try? JSONEncoder().encode(body),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            logger.debug("Отправляем JSON: \(jsonString)")
            request.httpBody = jsonData
        }

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }

            if let error = error {
                self.logger.error("❌ Ошибка обновления токена: \(error.localizedDescription)")
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                self.logger.error("❌ Некорректный ответ сервера при обновлении токена")
                return
            }

            if httpResponse.statusCode != 200 {
                if let data = data, let body = String(data: data, encoding: .utf8) {
                    self.logger.error("❌ Сервер вернул код \(httpResponse.statusCode): \(body)")
                } else {
                    self.logger.error("❌ Сервер вернул код \(httpResponse.statusCode), но тело пустое")
                }
                return
            }

            guard let data = data,
                  let newTokens = try? JSONDecoder().decode(AuthResponse.self, from: data) else {
                self.logger.error("❌ Ошибка декодирования нового токена")
                return
            }

            DispatchQueue.main.async {
                self.authService.accessToken = newTokens.accessToken
                self.authService.refreshToken = newTokens.refreshToken
                self.accessToken = newTokens.accessToken

                self.logger.info("✅ Токен обновлён")
            }
        }.resume()
    }



    
    func buildSocketURL() -> String? {
        guard let token = accessToken else { return nil }
        return "wss://yourserver/ws?token=\(token)"
    }


    
    func startResolvingIP(for hostname: String) {
        resolveRobotIP(hostname: hostname) { [weak self] ip in
            guard let self = self else { return }
            
            if let ip = ip {
                self.ipResolvedPublisher.send(ip)
            } else {
                self.ipResolveErrorPublisher.send("Не удалось разрешить IP")
            }
        }
    }
    
    
    func resolveRobotIP(hostname: String, completion: @escaping (String?) -> Void) {
        let host = CFHostCreateWithName(nil, hostname as CFString).takeRetainedValue()
        CFHostStartInfoResolution(host, .addresses, nil)
        
        var success: DarwinBoolean = false
        guard let addresses = CFHostGetAddressing(host, &success)?.takeUnretainedValue() as NSArray? else {
            completion(nil)
            return
        }
        
        for case let address as NSData in addresses {
            var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
            if getnameinfo(
                address.bytes.assumingMemoryBound(to: sockaddr.self),
                socklen_t(address.length),
                &hostname,
                socklen_t(hostname.count),
                nil,
                0,
                NI_NUMERICHOST
            ) == 0 {
                let ip = String(cString: hostname)
                if ip.contains(".") {
                    completion(ip)
                    return
                }
            }
        }
        completion(nil)
    }
}



