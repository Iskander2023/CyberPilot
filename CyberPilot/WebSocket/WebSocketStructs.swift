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


struct Command {
    static let moveForward = "iosMoveForward"
    static let moveBackward = "iosMoveBackward"
    static let turnLeft = "iosTurnLeft"
    static let turnRight = "iosTurnRight"
    static let stopTheMovement = "iosStopMovement"
    
    
}


enum SocketConnectionMode {
    case withRegistration(token: String)
    case plain
}
