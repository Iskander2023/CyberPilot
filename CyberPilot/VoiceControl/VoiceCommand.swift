//
//  VoiceCommand.swift
//  CyberPilot
//
//  Created by Aleksandr Chumakov on 2/07/25.
//

import Foundation


enum VoiceCommand: CaseIterable {
    case forward, backward, left, right, stop, start, hello

    var keywords: [String] {
        switch self {
        case .forward: return ["вперёд", "едь вперёд", "поехали", "поехал", "гони"]
        case .backward: return ["назад"]
        case .left: return ["влево", "налево"]
        case .right: return ["вправо", "направо"]
        case .stop: return ["стоп", "стой"]
        case .start: return ["поехали", "начинай"]
        case .hello: return ["привет", "здравствуй"]
        }
    }

    static func parse(from text: String) -> VoiceCommand? {
        let lowerText = text.lowercased()
        for command in VoiceCommand.allCases {
            for keyword in command.keywords {
                if lowerText.contains(keyword) {
                    return command
                }
            }
        }
        return nil
    }
}

