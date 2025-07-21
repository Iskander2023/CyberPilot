//
//  RobotsStrucs.swift
//  CyberPilot
//
//  Created by Admin on 21/07/25.
//

import Foundation



struct Robot: Identifiable, Codable {
    let robot_id: String
    let camera_url: String
    let status: Status
    let last_updated: Date

    enum CodingKeys: String, CodingKey {
        case robot_id, camera_url, status, last_updated
    }

    var id: String { robot_id }

    enum Status: String, Codable {
        case online
        case offline
    }

    var name: String {
        "Робот \(robot_id.prefix(6))" // или любое другое отображение
    }
}



