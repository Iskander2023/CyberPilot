//
//  OccupancyGridMap.swift
//  CyberPilot
//
//  Created by Aleksandr Chumakov on 14/05/25.
import SwiftUI


struct OccupancyGridMap: Codable, Equatable {
    let width: Int
    let height: Int
    let resolution: Double
    var data: [Int]

    static func == (lhs: OccupancyGridMap, rhs: OccupancyGridMap) -> Bool {
        return lhs.width == rhs.width &&
               lhs.height == rhs.height &&
               lhs.resolution == rhs.resolution &&
               lhs.data == rhs.data
    }
}


struct MapMessage: Codable {
    let data: [Int]
    let len: Int
}


struct MapCellColors {
    var unknown: Color = .clear       // -1
    var occupied: Color = .black      // 0
    var free: Color = .white          // 100
    var zoningBorder: Color = .gray   // 30
    var robot: Color = .orange        // 50
    var other: Color = .clear          // fallback
    var center: Color = .red

    // Предопределённые цвета для зон
    var zoningColors: [Color] = [.blue, .cyan, .pink, .green, .mint, .indigo, .yellow, .purple, .brown]

    func color(for value: Int) -> Color {
        switch value {
        case -1: return unknown
        case 0: return occupied
        case 100: return free
        case 30: return zoningBorder
        case 50: return robot
        case 60: return center
        case 31...:
            let index = value - 31
            if index < zoningColors.count {
                return zoningColors[index]
            } else {
                // Автоматически сгенерировать новый цвет, если не хватает
                return Color(hue: Double(index % 12) / 12.0, saturation: 0.7, brightness: 0.9)
            }
        default:
            return other
        }
    }
}


struct ZoneInfo: Identifiable {
    let id: Int         
    var name: String
    let center: CGPoint
}
