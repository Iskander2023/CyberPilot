//
//  MapLoader.swift
//  CyberPilot
//
//  Created by Admin on 12/05/25.
//

import Foundation
import Yams

func loadOccupancyGridMap(from path: String) -> OccupancyGridMap? {
    guard let yamlString = try? String(contentsOfFile: path),
          let parsed = try? Yams.load(yaml: yamlString) as? [String: Any],
          let info = parsed["info"] as? [String: Any],
          let width = info["width"] as? Int,
          let height = info["height"] as? Int,
          let resolution = info["resolution"] as? Double,
          let data = info["data"] as? [Int] else {
        return nil
    }
    return OccupancyGridMap(width: width, height: height, resolution: resolution, data: data)
}


