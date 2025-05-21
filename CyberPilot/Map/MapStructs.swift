//
//  OccupancyGridMap.swift
//  CyberPilot
//
//  Created by Aleksandr Chumakov on 14/05/25.



struct OccupancyGridMap: Codable, Equatable {
    let width: Int
    let height: Int
    let resolution: Double
    let data: [Int]

    static func == (lhs: OccupancyGridMap, rhs: OccupancyGridMap) -> Bool {
        return lhs.width == rhs.width &&
               lhs.height == rhs.height &&
               lhs.resolution == rhs.resolution &&
               lhs.data == rhs.data
    }
}

//struct MapMessage: Codable {
//    let type: String
//    let data: [Int]
//    let len: Double
//}

