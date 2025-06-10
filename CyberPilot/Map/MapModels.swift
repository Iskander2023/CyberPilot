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
    var unknown: Color = .gray 
    var free: Color = .white             // -1 свободноое пространство
    var occupied: Color = .black         // 100 объекты(стены/препятствия)
    var robot: Color = .orange           // 500 положение робота
    var zoning: Color = .mint            // 300 зонирование помоещений
    var other: Color = .red              // другие значения
    
    func color(for value: Int) -> Color {
        switch value {
        case -1: return unknown
        case 0: return occupied
        case 100: return free
        case 300: return zoning
        case 500: return robot
        default: return other
        }
    }
}
