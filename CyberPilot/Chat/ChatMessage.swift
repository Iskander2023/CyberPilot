//
//  ChatMessage.swift
//  CyberPilot
//
//  Created by Admin on 23/07/25.
//

import Foundation


struct ChatMessage: Identifiable, Equatable {
    let id = UUID()
    let sender: Sender
    let text: String
    let time: Date
    
    enum Sender: Equatable {
        case user
        case robot
    }
}
