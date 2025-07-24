//
//  WebSocketStructs.swift
//  CyberPilot
//
//  Created by Aleksandr Chumakov on 23/05/25.
//

import Foundation


struct MessageType: Decodable {
    let type: String
}


enum SocketConnectionMode {
    case withRegistration(token: String)
    case plain
}


struct ChatMessageDTO: Decodable {
    let type: String
    let text: String
    // можно добавить sender, time и т.п. если нужно
}
