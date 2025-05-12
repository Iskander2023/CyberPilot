//
//  IndoorMapEditor.swift
//  CyberPilot
//
//  Created by Aleksandr Chumakov on 7/05/25.
//
//import Foundation
//import Yams
//import SwiftUI
//
//
//
//class MapModel: ObservableObject {
//    @Published var map: OccupancyGridMap?
//
//    func loadOccupancyGridMap(from path: String) {
//        guard let yamlString = try? String(contentsOfFile: path),
//              let parsed = try? Yams.load(yaml: yamlString) as? [String: Any],
//              let info = parsed["info"] as? [String: Any],
//              let width = info["width"] as? Int,
//              let height = info["height"] as? Int,
//              let resolution = info["resolution"] as? Double,
//              let data = parsed["data"] as? [Int] else {
//            return
//        }
//
//        // Обновляем карту
//        self.map = OccupancyGridMap(width: width, height: height, resolution: resolution, data: data)
//    }
//
//    // Метод для динамического обновления данных карты (например, через API)
//    func updateMapData(newData: [Int]) {
//        guard var currentMap = self.map else { return }
//        currentMap.data = newData
//        self.map = currentMap // обновляем состояние
//    }
//}
