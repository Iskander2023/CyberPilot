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
    let mapCacheManager = GenericCacheManager<OccupancyGridMap>(filename: "cached_map.json")
    private let socketListener: SocketListener
    private let logger = CustomLogger(logLevel: .info, includeMetadata: false)
    private let mapUpdateTime: TimeInterval = 10
    private var timerCancellable: AnyCancellable?
    var socketIp: String = "ws://172.16.17.79:8765"
//    var noLocalIp: String = "http://192.168.0.201:8000/map.yaml" // для запуска на телефоне
    var noLocalIp: String = "http://127.0.0.1:8000/map.yaml"
    
    
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
        logger.info("✅ setupFromLocalFile вызван")
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
    
    
    // метод установки новых значений ячейкам карты
    func setValue(_ value: Int, forCells cells: [CGPoint]) {
        guard var currentMap = map else {
            print("Карта не загружена")
            return
        }
        for cell in cells {
            let x = Int(cell.x)
            let y = Int(cell.y)
            guard x >= 0, x < currentMap.width,
                  y >= 0, y < currentMap.height else {
                continue
            }
            let index = y * currentMap.width + x
            if currentMap.data[index] == 100 {
                currentMap.data[index] = value
            }
        }
        self.map = currentMap
        self.mapCacheManager.save(currentMap)
    }
    
    
    
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
    
    
    // Преобразование: экран → карта
    func convertToMapCoordinates(_ point: CGPoint, offset: CGSize, scale: CGFloat, in geometry: CGSize) -> CGPoint {
        let center = CGPoint(x: geometry.width / 2, y: geometry.height / 2)
        let translatedX = (point.x - center.x - offset.width) / scale
        let translatedY = (point.y - center.y - offset.height) / scale
        return CGPoint(x: translatedX, y: translatedY)
    }
    
    
    // Преобразование: карта → экран
    func convertToScreenCoordinates(_ point: CGPoint, offset: CGSize, scale: CGFloat, in geometry: CGSize) -> CGPoint {
        let center = CGPoint(x: geometry.width / 2, y: geometry.height / 2)
        let screenX = point.x * scale + center.x + offset.width
        let screenY = point.y * scale + center.y + offset.height
        return CGPoint(x: screenX, y: screenY)
    }

    
    func getCellsAlongLineBetweenCells(
        from start: (Int, Int),
        to end: (Int, Int)
    ) -> [CGPoint] {
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
}
