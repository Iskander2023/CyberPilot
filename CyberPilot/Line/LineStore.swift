//
//  LineStore.swift
//  CyberPilot
//
//  Created by Aleksandr Chumakov on 16/05/25.
//

import SwiftUI
import Combine

class LineStore: ObservableObject {
    @Published var lines: [Line] = []
    @Published var robotPosition: CGPoint? = nil
    var robotManager: RobotManager
    private var socketManager: SocketManager?
    private let logger = CustomLogger(logLevel: .info, includeMetadata: false)
    private let cacheFilename = "cached_lines.json"
    private let mapUpdateTime: TimeInterval = 10
    //private var timerCancellable: AnyCancellable?
    var socketIp: String = "ws://172.16.17.79:8765"
    var mapApdateTime: Double = 5
    
    
    init(robotManager: RobotManager) {
        self.robotManager = robotManager
        socketManager = SocketManager(robotManager: robotManager)
        loadFromCache()
    }
    

    func startLoadingLines() {
        guard let socketManager = socketManager else { return }
        socketManager.connectSocket(urlString: socketIp)
        socketManager.onLineMessageReceived = { [weak self] lines, center in
            guard let self = self else { return }
            let linesData = lines
            let newLines = parseLine(from: linesData)
            self.updateIfChanged(newLines: newLines, center: center)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            guard let self = self else { return }
            if !socketManager.isConnected {
                socketManager.disconnectSocket()
                self.logger.error("ℹ️ Сокет не подключён через 5 секунд — соединение прервано")
            } else {
                self.logger.info("ℹ️ Сокет успешно подключён")
            }
        }
    }
        
    
    
    func stopLoadingLines() {
        if let socketManager = socketManager, socketManager.isConnected {
                socketManager.disconnectSocket()
                logger.info("ℹ️ Загрузка линий остановлена и сокет отключён")
            } else {
                logger.info("ℹ️ Загрузка линий остановлена (сокет уже был отключён)")
            }
    }
    
    
    func parseLine(from rawData: [[[Double]]]) -> [Line] {
        return rawData.map { line in
        let points = line.map { pt in
            CodablePoint(x: CGFloat(pt[0]), y: CGFloat(pt[1]))
        }
        return Line(points: points)
        }
    }
    
    
    func updateIfChanged(newLines: [Line], center: CGPoint, completion: ((Bool) -> Void)? = nil) {
        DispatchQueue.main.async {
            if newLines != self.lines {
                self.updateLines(newLines)
                if self.robotPosition != center {
                    self.robotPosition = center
                }
                //self.logger.info("✅ Линии обновлены")
                completion?(true)
            } else {
                //self.logger.info("ℹ️ Линии не изменились — обновление не требуется")
                completion?(false)
            }
        }
        
    }
    
    
    func updateLines(_ newLines: [Line]) {
            lines = newLines
            saveToCache()
        }
    
    
    func removeLine(_ line: Line) {
        lines.removeAll { $0.id == line.id }
        saveToCache()
    }
    

    func saveToCache() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let cachedLines = CachedLines(lines: lines, robotPosition: robotPosition)
        do {
            let data = try encoder.encode(cachedLines)
            let url = getDocumentsDirectory().appendingPathComponent(cacheFilename)
            try data.write(to: url)
        } catch {
            print("❌ Ошибка при сохранении линий: \(error)")
        }
    }
    

    func loadFromCache() {
        let url = getDocumentsDirectory().appendingPathComponent(cacheFilename)
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let cachedLines = try decoder.decode(CachedLines.self, from: data)
            DispatchQueue.main.async {
                self.lines = cachedLines.lines
                self.robotPosition = cachedLines.robotPosition
            }
            self.logger.info("✅ Линии загружены из кэша")
        } catch {
            self.logger.info("❌ Ошибка при загрузке линий из кэша: \(error)")
        }
    }

    
    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
}



extension Line: Equatable {
    static func == (lhs: Line, rhs: Line) -> Bool {
        return lhs.id == rhs.id && lhs.points == rhs.points
    }
}

extension CodablePoint: Equatable {
    static func == (lhs: CodablePoint, rhs: CodablePoint) -> Bool {
        abs(lhs.x - rhs.x) < 0.001 && abs(lhs.y - rhs.y) < 0.001
    }
}
