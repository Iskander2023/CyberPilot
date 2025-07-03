//
//  VoiceCommand.swift
//  CyberPilot
//
//  Created by Aleksandr Chumakov on 2/07/25.
//

import Foundation


enum VoiceCommand: String, CaseIterable {
    case forward, backward, left, right, stop, forwardLeft, forwardRight

    var keywords: [String] {
        switch self {
        case .forward: return ["вперёд", "едь вперёд", "поехали", "поехал", "гони", "прямо"]
        case .backward: return ["назад", "взад"]
        case .left: return ["влево"]
        case .right: return ["вправо"]
        case .stop: return ["стоп", "стой", "тормози", "стоять", "оп", "ааааааа"]
        case .forwardLeft: return ["левее"]
        case .forwardRight: return ["правее"]
        }
    }


    static func parse(from text: String) -> VoiceCommand? {
        let lowerText = text.lowercased()
        var latestMatch: (command: VoiceCommand, index: String.Index)?

        for command in VoiceCommand.allCases {
            for keyword in command.keywords {
                var searchRange = lowerText.startIndex..<lowerText.endIndex
                while let range = lowerText.range(of: keyword, options: [], range: searchRange) {
                    if latestMatch == nil || range.lowerBound > latestMatch!.index {
                        latestMatch = (command, range.lowerBound)
                    }
                    searchRange = range.upperBound..<lowerText.endIndex
                }
            }
        }
        
        return latestMatch?.command
    }
}

