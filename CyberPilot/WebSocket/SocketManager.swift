//
//  Socket.swift
//  Robot_Controller
//
//  Created by Aleksandr Chumakov on 18/03/25.
//
import Starscream
import Combine


class SocketManager: NSObject, WebSocketDelegate {
    weak var delegate: SocketDelegate?
    var socket: WebSocket!
    var token: String?
    var isConnected: Bool = false
    var robotManager: RobotManager
    var connectionMode: SocketConnectionMode = .plain
    var onMapArrayReceived: (([Int], Int) -> Void)?
    var onLineMessageReceived: (([[[Double]]], CGPoint) -> Void)?
    let logger = CustomLogger(logLevel: .info, includeMetadata: false)
    let connectionStatus = PassthroughSubject<Bool, Never>()
    let receivedMessages = PassthroughSubject<[String: Any], Never>()
    private var cancellables = Set<AnyCancellable>()
    
    
    init(robotManager: RobotManager, connectionMode: SocketConnectionMode = .plain) {
        self.robotManager = robotManager
        self.connectionMode = connectionMode
        super.init()
        self.robotManager.$token
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
                self.delegate?.didResolveRobotIP(ip)
            } else {
                self.delegate?.didFailToResolveIP(error: "Не удалось разрешить IP")
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
        socket.delegate = self
        socket.connect()
    }

    
    func disconnectSocket() {
        if let socket = socket{
            socket.disconnect()
        }
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
            //self.logger.info("Отправка команды: \(command)")
            socket.write(string: command)
        } else {
            self.logger.info("Ошибка отправки команды: соединение не установлено.")
        }
    }
    
    private func parseJSONMessage(_ message: String) -> [String: Any]? {
        guard let data = message.data(using: .utf8) else { return nil }
        return try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
    }
    
    private func handleTextMessage(_ message: String) {
        guard let data = message.data(using: .utf8) else {
            logger.info("Не удалось конвертировать сообщение в Data")
            return
        }
        
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
            guard let jsonDict = jsonObject as? [String: Any],
                  let messageType = jsonDict["type"] as? String else {
                logger.info("Сообщение не содержит поле 'type' или не является JSON")
                return
            }
            switch messageType {
            case "map":
                handleMapMessage(data: data)
                
            case "line":
                handleLineMessage(data: data)
                
            default:
                logger.info("Получен неизвестный тип сообщения: \(messageType)")
                receivedMessages.send(jsonDict)
            }
            
        } catch {
            logger.info("Ошибка при парсинге сообщения: \(error.localizedDescription)")
        }
    }
    
    
    private func handleMapMessage(data: Data) {
        do {
            let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
            let dataArray = json["data"] as! [Int]
            let len = json["len"] as! Int
            onMapArrayReceived?(dataArray, len)
        } catch {
            logger.error("Ошибка обработки MapMessage: \(error.localizedDescription)")
        }
    }
    
    
    private func handleLineMessage(data: Data) {
        do {
            let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
            let lines = json["data"] as! [[[Double]]]
            let center = json["center"] as! [Double]
            let centerPoint = CGPoint(x: center[0], y: center[1])
            //logger.info("Получены линии: длина \(lines.count), \(centerPoint)")
            onLineMessageReceived?(lines, centerPoint)
        } catch {
            logger.info("Ошибка декодирования MapMessage: \(error.localizedDescription)")
        }
    }
    

    func didReceive(event: WebSocketEvent, client: WebSocketClient) {
        switch event {
        case .connected(let headers):
            isConnected = true
            self.logger.info("Connection established. Headers: \(headers)")
        
            switch connectionMode {
            case .withRegistration(let token):
                let reg: [String: Any] = [
                    "type": "register",
                    "role": "operator",
                    "id": "robot1",
                    "robotId": "robot1",
                    "token": token
                ]
                sendJSONCommand(reg)
            case .plain:
                logger.info("Режим без регистрации — регистрация не требуется.")
            }
            DispatchQueue.main.async {
                self.delegate?.socketManager(self, didUpdateConnectionStatus: true)
                self.connectionStatus.send(true)
            }
        case .disconnected(let reason, let code):
            isConnected = false //
            //isConnected = true // отключение для тестов
            self.logger.info("Connection closed. Reason: \(reason), Код: \(code)")
            DispatchQueue.main.async {
                self.delegate?.socketManager(self, didUpdateConnectionStatus: false)
                self.connectionStatus.send(false)
            }
//            DispatchQueue.main.async {
//                self.delegate?.socketManager(self, didUpdateConnectionStatus: true)
//                self.connectionStatus.send(true)
//            }
        case .text(let message):
            //self.logger.info("Text message from a robot: \(message)")
            guard parseJSONMessage(message) != nil else {
                logger.info("Не удалось распарсить JSON")
                return
            }
            handleTextMessage(message)

        case .binary(let data):
            self.logger.info("Received binary data: \(data)")
        case .pong(let pongData):
            self.logger.info("Received PONG: \(String(describing: pongData))")
        case .ping(let pingData):
            self.logger.info("Received PING: \(String(describing: pingData))")
        case .error(let error):
            if let error = error {
                self.logger.info("Error WebSocket: \(error.localizedDescription)")}
        case .viabilityChanged(let isViable):
            self.logger.info("Change in Vitality: \(isViable)")
        case .reconnectSuggested(let shouldReconnect):
            self.logger.info("Reconnection suggested: \(shouldReconnect)")
        case .cancelled:
            //isConnected = true
            isConnected = false
            self.logger.info("Connection canceled.")
            DispatchQueue.main.async {
                self.delegate?.socketManager(self, didUpdateConnectionStatus: false)
            }
//            DispatchQueue.main.async {
//                self.delegate?.socketManager(self, didUpdateConnectionStatus: true)
//            }
        case .peerClosed:
            //isConnected = true
            isConnected = false
            self.logger.info("Connection closed")
            DispatchQueue.main.async {
                self.delegate?.socketManager(self, didUpdateConnectionStatus: false)
                self.delegate?.socketManager(self, didReceiveResponse: "Connection closed.")
            }
//            DispatchQueue.main.async {
//                self.delegate?.socketManager(self, didUpdateConnectionStatus: true)
//                self.delegate?.socketManager(self, didReceiveResponse: "Connection closed.")
//            }
        }
    }
    
}


enum SocketConnectionMode {
    case withRegistration(token: String)
    case plain
}


protocol SocketDelegate: AnyObject {
    func socketManager(_ manager: SocketManager, didUpdateConnectionStatus isConnected: Bool)
    func socketManager(_ manager: SocketManager, didReceiveResponse response: String)
    func didResolveRobotIP(_ ip: String)
    func didFailToResolveIP(error: String?)
}
