//
//  Socket.swift
//  Robot_Controller
//
//  Created by Aleksandr Chumakov on 18/03/25.
//
import UIKit
import Starscream

class SocketManager: NSObject, WebSocketDelegate {
    let logger = CustomLogger(logLevel: .info, includeMetadata: false)
    var socket: WebSocket!
    var isLocalConnected: Bool = false
    weak var delegate: SocketDelegate?

    
    override init() {
        super.init()
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
        sendCommand(jsonString)
    }


    
    func sendCommand(_ command: String) {
        if isLocalConnected {
            self.logger.info("Отправка команды: \(command)")
            socket.write(string: command)
        } else {
            self.logger.info("Ошибка: соединение не установлено.")
        }
    }


    func didReceive(event: WebSocketEvent, client: WebSocketClient) {
        switch event {
        case .connected(let headers):
            isLocalConnected = true
            self.logger.info("Connection established. Headers: \(headers)")
            DispatchQueue.main.async {
                self.delegate?.socketManager(self, didUpdateConnectionStatus: true)}
        case .disconnected(let reason, let code):
            isLocalConnected = false
            self.logger.info("Connection closed. Reason: \(reason), Код: \(code)")
            DispatchQueue.main.async {
                self.delegate?.socketManager(self, didUpdateConnectionStatus: false)}
        case .text(let message):
            self.logger.info("Text message from a robot: \(message)")
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
            isLocalConnected = false
            self.logger.info("Connection canceled.")
            DispatchQueue.main.async {
                self.delegate?.socketManager(self, didUpdateConnectionStatus: false)
            }
        case .peerClosed:
            isLocalConnected = false
            self.logger.info("Connection closed")
            DispatchQueue.main.async {
                self.delegate?.socketManager(self, didUpdateConnectionStatus: false)
                self.delegate?.socketManager(self, didReceiveResponse: "Connection closed.")}
        }
    }
    
}


protocol SocketDelegate: AnyObject {
    func socketManager(_ manager: SocketManager, didUpdateConnectionStatus isConnected: Bool)
    func socketManager(_ manager: SocketManager, didReceiveResponse response: String)
    func didResolveRobotIP(_ ip: String)
    func didFailToResolveIP(error: String?)
}
