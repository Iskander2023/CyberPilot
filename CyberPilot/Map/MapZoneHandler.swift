//
//  MapZoneHandler.swift
//  CyberPilot
//
//  Created by Aleksandr Chumakov on 17/06/25.
//

import Foundation



class MapZoneHandler: ObservableObject {
    @Published var zones: [ZoneInfo] = []
    var mapManager: MapManager
    var centerZoneList: [CGPoint] = []
    let mapCacheManager = GenericCacheManager<OccupancyGridMap>(filename: "cached_map.json")
    var currentRobotIndex: Int?
    
    init(mapManager: MapManager) {
        self.mapManager = mapManager
    }
    
    
    //метод получения индексов массива по точкам
    private func validIndices(for cells: [CGPoint], in map: OccupancyGridMap) -> [Int] {
        var indices = [Int]()
        for cell in cells {
            let x = Int(cell.x)
            let y = Int(cell.y)
            guard x >= 0, x < map.width,
                  y >= 0, y < map.height else {
                continue
            }
            let index = y * map.width + x
            indices.append(index)
        }
        return indices
    }
    
    
    // сохранение индекса массива робота
    func saveRobotPoint(index: Int) {
        currentRobotIndex = index
    }
    
    
    // обновление точки робота на карте(используется после заливки)
    func putARobotPoint() {
        guard var currentMap = mapManager.map else {
            print("Карта не загружена")
            return
        }
        currentMap.data[currentRobotIndex ?? 0] = 50
        self.mapManager.map = currentMap
        self.mapCacheManager.save(currentMap)
    }
    
    
    // метод установки новых значений ячейкам карты
    func setValue(_ value: Int, forCells cells: [CGPoint], fillPoints: Int, robotPoint: Int) {
        guard var currentMap = mapManager.map else {
            print("Карта не загружена")
            return
        }
        let indices = validIndices(for: cells, in: currentMap)
        for index in indices {
            if currentMap.data[index] == robotPoint {
                saveRobotPoint(index: index)
                currentMap.data[index] = value
            }
            else if currentMap.data[index] != fillPoints {
                currentMap.data[index] = value
            }
        }
        self.mapManager.map = currentMap
        self.mapCacheManager.save(currentMap)
    }
    
    
    
    // Метод для изменения названия зоны по id
    func renameZone(id: Int, newName: String) {
        if let index = zones.firstIndex(where: { $0.id == id }) {
            zones[index].name = newName
        }
    }
    
    
    
    // получение точки координат центра зоны
    func getCenterZone(cells: [CGPoint]) -> CGPoint {
        var sumX = 0.0
        var sumY = 0.0
        let count = Double(cells.count)
        for cell in cells {
            sumX += Double(cell.x)
            sumY += Double(cell.y)
        }
        let avgX = sumX / count
        let avgY = sumY / count
        return CGPoint(x: avgX, y: avgY)
    }
    
    // заливка зон карты
    func mapZoneFills() {
        var existingNames = [Int: String]() // сохраняем старые названия по id
        for zone in zones {
            existingNames[zone.id] = zone.name
        }
        zones = []
        centerZoneList = []
        let zeroContours = findIsolatedRegions(in: mapManager.map?.data ?? [], width: mapManager.map?.width ?? 30, valueRange: 31...100)
        for (i, contour) in zeroContours.enumerated() {
            let center = getCenterZone(cells: contour)
            centerZoneList.append(center) //
            let id = 31 + i
            let name: String
            if let existing = existingNames[id], !existing.starts(with: "Зона ") {
                name = existing
            } else {
                name = "Зона \(i+1)"
            }
            setValue(id, forCells: contour, fillPoints: 0, robotPoint: 50)
            putARobotPoint()
            let zone = ZoneInfo(id: id, name: name, center: center)
            zones.append(zone)
        }
        setValue(60, forCells: centerZoneList, fillPoints: 0, robotPoint: 50) // добавлено для визуализации
    }
    
    
    // поиск замкнутых зон на карте
    func findIsolatedRegions(in data: [Int], width: Int, valueRange: ClosedRange<Int>) -> [[CGPoint]] {
        let height = data.count / width
        var visited = Array(repeating: false, count: data.count)
        var result = [[CGPoint]]()
        
        func isInside(_ r: Int, _ c: Int) -> Bool {
            return r >= 0 && c >= 0 && r < height && c < width
        }
        
        let directions = [(0,1), (1,0), (0,-1), (-1,0)]
        
        for row in 0..<height {
            for col in 0..<width {
                let idx = row * width + col
                // Проверяем, входит ли значение в диапазон и не посещено ли
                guard valueRange.contains(data[idx]) && !visited[idx] else { continue }
                
                var region = [CGPoint]()
                var queue = [(row, col)]
                var isTouchingBorder = false
                
                while !queue.isEmpty {
                    let (r, c) = queue.removeFirst()
                    let i = r * width + c
                    
                    guard isInside(r, c), valueRange.contains(data[i]), !visited[i] else { continue }
                    visited[i] = true
                    region.append(CGPoint(x: c, y: r))
                    
                    if r == 0 || r == height - 1 || c == 0 || c == width - 1 {
                        isTouchingBorder = true
                    }
                    
                    for (dr, dc) in directions {
                        let nr = r + dr
                        let nc = c + dc
                        if isInside(nr, nc), valueRange.contains(data[nr * width + nc]), !visited[nr * width + nc] {
                            queue.append((nr, nc))
                        }
                    }
                }
                
                if !region.isEmpty && !isTouchingBorder {
                    result.append(region)
                }
            }
        }
        
        return result
    }
    
    
}
