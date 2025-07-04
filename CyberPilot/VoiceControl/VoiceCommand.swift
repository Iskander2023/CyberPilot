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
        case .forward: return AppConfig.VoiceControl.forward
        case .backward: return AppConfig.VoiceControl.backward
        case .left: return AppConfig.VoiceControl.left
        case .right: return AppConfig.VoiceControl.right
        case .stop: return AppConfig.VoiceControl.stop
        case .forwardLeft: return AppConfig.VoiceControl.forwardLeft
        case .forwardRight: return AppConfig.VoiceControl.forwardRight
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

