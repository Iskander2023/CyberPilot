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
    
    let connectionStatus = PassthroughSubject<Bool, Never>()
    let receivedResponses = PassthroughSubject<String, Never>()
    let receivedMessages = PassthroughSubject<[String: Any], Never>()
    let ipResolvedPublisher = PassthroughSubject<String, Never>()
    let ipResolveErrorPublisher = PassthroughSubject<String?, Never>()

    var socket: WebSocket!
    var token: String?
    var authService: AuthService
    var connectionMode: SocketConnectionMode = .plain
    var onMapArrayReceived: (([Int], Int) -> Void)?
    var onLineMessageReceived: (([[[Double]]], CGPoint) -> Void)?
    let logger = CustomLogger(logLevel: .info, includeMetadata: false)
    
    private var cancellables = Set<AnyCancellable>()
    
    
    init(authService: AuthService, connectionMode: SocketConnectionMode = .plain) {
        self.authService = authService
        self.connectionMode = connectionMode
        super.init()
            self.authService.$token
                .sink { [weak self] newToken in
                    guard let self = self else { return }
                    self.token = newToken
                }
                .store(in: &cancellables)
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
    
    
    func connectSocket(urlString: String, timeout: TimeInterval = 5) {
        guard !isConnected else {
            logger.info("Уже подключено.")
            return
        }
        guard let url = URL(string: urlString) else {
            self.logger.info("Ошибка: неверный URL")
            return
        }
        var request = URLRequest(url: url)
        request.timeoutInterval = timeout
        socket = WebSocket(request: request)
        self.socket.delegate = self
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
            self.logger.debug("Ошибка отправки команды: соединение не установлено.")
            return
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
    
    
    private func makeRegistrationPayload(token: String) -> [String: Any] {
        return [
            "type": "register",
            "role": "operator",
            "id": "robot1",
            "robotId": "robot1",
            "token": token
        ]
    }

    
    
    func handleConnected(headers: [String: String]) {
        isConnected = true
        connectionError = nil
        logger.info("Connection established. Headers: \(headers)")
        switch connectionMode {
        case .withRegistration(let token):
            let reg = makeRegistrationPayload(token: token)
            sendJSONCommand(reg)
        case .plain:
            logger.info("Режим без регистрации — регистрация не требуется.")
        }
        self.connectionStatus.send(true)
    }
    
    
    func handleDisconnected(reason: String, code: UInt16) {
        isConnected = false
        connectionError = "Disconnected: \(reason) (code \(code))"
        logger.info("Connection closed. Reason: \(reason), Код: \(code)")
//        self.connectionStatus.send(true) // заглушка для тестов
        connectionStatus.send(false)
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
        self.receivedResponses.send("Connection canceled.")
        self.connectionStatus.send(false)
//        self.connectionStatus.send(true) // заглушка для тестов
    }
    
    
    func handlePeerClosed() {
        isConnected = false
        logger.info("Connection closed")
//        self.connectionStatus.send(true) // заглушка для тестов
        self.connectionStatus.send(false)
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
}


enum SocketConnectionMode {
    case withRegistration(token: String)
    case plain
}
