//
//  OccupancyGridMap.swift
//  CyberPilot
//
//  Created by Aleksandr Chumakov on 14/05/25.



struct OccupancyGridMap: Codable {
    let width: Int
    let height: Int
    let resolution: Double
    var data: [Int]
}

