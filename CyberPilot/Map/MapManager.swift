//
//  MapManager.swift
////  CyberPilot
////
////  Created by Aleksandr Chumakov on 7/05/25.
////
import Foundation
import Yams
import Combine

final class MapManager: ObservableObject {
    @Published var map: OccupancyGridMap?
    @Published var zones: [ZoneInfo] = []
    let mapCacheManager = GenericCacheManager<OccupancyGridMap>(filename: "cached_map.json")
    private let socketListener: SocketListener
    private let logger = CustomLogger(logLevel: .info, includeMetadata: false)
    private let mapUpdateTime: TimeInterval = 10
    private var timerCancellable: AnyCancellable?
    var socketIp: String = "ws://172.16.17.79:8765"
//    var noLocalIp: String = "http://192.168.0.201:8000/map.yaml" // для запуска на телефоне
    var noLocalIp: String = "http://127.0.0.1:8000/map.yaml"
    var centerZoneList: [CGPoint] = []
    var currentRobotIndex: Int?
    
    
    init(authService: AuthService) {
        map = mapCacheManager.load()
        socketListener = SocketListener(authService: authService, socketIp: socketIp)
    }
    
    
    func updateIfChanged(with dataArray: [Int], len: Int,  completion: ((Bool) -> Void)? = nil) {
        let width = len
        let height = len
        let resolution = 0.1 
        guard dataArray.count == width * height else {
            logger.error("❌ Размер массива не совпадает с размерами карты.")
            return
        }
        let newMap = OccupancyGridMap(width: width, height: height, resolution: resolution, data: dataArray)
        DispatchQueue.main.async {
            if self.map != newMap {
                self.logger.debug("🔄 Карта изменилась — сохраняем в кэш")
                self.map = newMap
                self.mapCacheManager.save(newMap)
                completion?(true)
            } else {
                self.logger.debug("✅ Карта не изменилась — пропускаем кэширование")
                completion?(false)
            }
        }
    }
    
    
    func setupFromLocalFile() {
        logger.info("✅ загрузка с локального файла")
        downloadMapFromLocalFile(from: noLocalIp)
        //setupRefreshTimer() // закомичено для тестов
        
    }
    
    
    func setupRefreshTimer() {
        timerCancellable?.cancel()
        timerCancellable = Timer
            .publish(every: mapUpdateTime, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.downloadMapFromLocalFile(from: self.noLocalIp)
            }
    }
    
    
    func startLoadingMap() {
        socketListener.startListening(for: .map)
        socketListener.onMapReceived = { [weak self] array, len in
                    self?.updateIfChanged(with: array, len: len)
                }
        }
    
    
    func stopLoadingMap() {
        socketListener.stopListening()
        timerCancellable?.cancel()
    }
    
    
    // заливка зон карты
    func mapZoneFills() {
        var existingNames = [Int: String]() // сохрани старые названия по id
        for zone in zones {
            existingNames[zone.id] = zone.name
        }
        zones = []
        centerZoneList = []
        let zeroContours = findIsolatedRegions(in: map?.data ?? [], width: map?.width ?? 30, valueRange: 31...100)
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
    
    
    func putARobotPoint() {
        guard var currentMap = map else {
            print("Карта не загружена")
            return
        }
        currentMap.data[currentRobotIndex ?? 0] = 50
        self.map = currentMap
        self.mapCacheManager.save(currentMap)
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
    
    // сохранение индекса робота на карте
    func saveRobotPoint(index: Int) {
        currentRobotIndex = index
    }
    
    
    // метод установки новых значений ячейкам карты
    func setValue(_ value: Int, forCells cells: [CGPoint], fillPoints: Int, robotPoint: Int) {
        guard var currentMap = map else {
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
        self.map = currentMap
        self.mapCacheManager.save(currentMap)
    }
    
    
    // перевод CGPoint в позицию на Canvas
    func convertMapPointToScreen(_ point: CGPoint, map: OccupancyGridMap, in size: CGSize, scale: CGFloat, offset: CGSize) -> CGPoint {
        let (cellSize, offsetX, offsetY) = calculateCellSize(in: size, map: map, scale: scale, offset: offset)
        let screenX = point.x * cellSize + offsetX + cellSize / 2
        let screenY = point.y * cellSize + offsetY + cellSize / 2
        return CGPoint(x: screenX, y: screenY)
    }
    
    
    // Метод для изменения названия зоны по id
    func renameZone(id: Int, newName: String) {
        if let index = zones.firstIndex(where: { $0.id == id }) {
            zones[index].name = newName
        }
    }


    // расчет положения текущей на карте
    func calculateCellSize(in size: CGSize, map: OccupancyGridMap, scale: CGFloat, offset: CGSize) -> (cellSize: CGFloat, offsetX: CGFloat, offsetY: CGFloat) {
        let mapAspect = CGFloat(map.width) / CGFloat(map.height)
        let viewAspect = size.width / size.height
        let cellSize: CGFloat
        let totalWidth: CGFloat
        let totalHeight: CGFloat
        if mapAspect > viewAspect {
            cellSize = size.width / CGFloat(map.width) * scale
            totalWidth = size.width * scale
            totalHeight = CGFloat(map.height) * cellSize
        } else {
            cellSize = size.height / CGFloat(map.height) * scale
            totalHeight = size.height * scale
            totalWidth = CGFloat(map.width) * cellSize
        }
        let offsetX = (size.width - totalWidth) / 2 + offset.width
        let offsetY = (size.height - totalHeight) / 2 + offset.height
        return (cellSize, offsetX, offsetY)
    }
    
    
    func convertPointToCell(point: CGPoint, in size: CGSize, map: OccupancyGridMap, scale: CGFloat, offset: CGSize) -> CGPoint? {
        let (cellSize, offsetX, offsetY) = calculateCellSize(
                in: size,
                map: map,
                scale: scale,
                offset: offset
            )
        let x = Int((point.x - offsetX) / cellSize)
        let y = Int((point.y - offsetY) / cellSize)
        guard x >= 0, x < map.width, y >= 0, y < map.height else {
            return nil
        }
        return CGPoint(x: x, y: y)
    }
    
    // вычисляет координаты массива точек с помощью алгоритма Брезенхема(от начальной точки до конечной)
    func getCellsAlongLineBetweenCells(from start: (Int, Int), to end: (Int, Int)) -> [CGPoint] {
        let (x0, y0) = start
        let (x1, y1) = end
        
        var points = [CGPoint]()
        
        let dx = abs(x1 - x0)
        let dy = abs(y1 - y0)
        let sx = x0 < x1 ? 1 : -1
        let sy = y0 < y1 ? 1 : -1
        var err = dx - dy
        var currentX = x0
        var currentY = y0
        while true {
            points.append(CGPoint(x: currentX, y: currentY))
            if currentX == x1 && currentY == y1 {
                break
            }
            let e2 = 2 * err
            if e2 > -dy {
                err -= dy
                currentX += sx
            }
            if e2 < dx {
                err += dx
                currentY += sy
            }
        }
        return points
    }

    
    // Загрузка из локальной сети(из файла yaml)
    func downloadMapFromLocalFile(from urlString: String, completion: ((Bool) -> Void)? = nil) {
        guard let url = URL(string: urlString) else {
            completion?(false)
            return
        }
        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let self = self else { return }
            
            guard let data = data,
                  let string = String(data: data, encoding: .utf8),
                  let parsed = try? Yams.load(yaml: string) as? [String: Any],
                  let info = parsed["info"] as? [String: Any],
                  let width = info["width"] as? Int,
                  let height = info["height"] as? Int,
                  let resolution = info["resolution"] as? Double,
                  let data = info["data"] as? [Int] else {
                DispatchQueue.main.async {
                    completion?(false)
                }
                return
            }
            let newMap = OccupancyGridMap(width: width, height: height, resolution: resolution, data: data)
            DispatchQueue.main.async {
                if self.map != newMap {
                    self.logger.info("🔄 Карта изменилась — сохраняем в кэш")
                    self.map = newMap
                    self.mapCacheManager.save(newMap)
                    completion?(true)
                } else {
                    self.logger.info("✅ Карта не изменилась")
                    completion?(false)
                }
            }
        }.resume()
    }
    
    
    
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
