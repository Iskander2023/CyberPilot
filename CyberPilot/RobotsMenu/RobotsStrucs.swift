//
//  RobotsStrucs.swift
//  CyberPilot
//
//  Created by Aleksandr Chumakov on 21/07/25.
//

import Foundation


struct Robot: Identifiable, Codable {
    let robot_id: String
    let camera_url: String
    let status: Status
    let last_updated: Date



    var id: String { robot_id }

    enum Status: String, Codable {
        case online
        case offline
    }
}



