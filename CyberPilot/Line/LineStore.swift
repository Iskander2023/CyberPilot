//
//  LineStore.swift
//  CyberPilot
//
//  Created by Aleksandr Chumakov on 16/05/25.
//

import SwiftUI
import Combine

class LineStore: ObservableObject {
    @Published var segments: [ShapeSegment] = []
    @Published var robotPosition: CGPoint? = nil
    var authServise: AuthService
    private var socketManager: SocketManager?
    private let logger = CustomLogger(logLevel: .info, includeMetadata: false)
    private let cacheFilename = "cached_segments.json"
    private let mapUpdateTime: TimeInterval = 10
    //private var timerCancellable: AnyCancellable?
    var socketIp: String = "ws://172.16.17.79:8765"
    var mapApdateTime: Double = 5
    
    
    
    init(authServise: AuthService) {
        self.authServise = authServise
        socketManager = SocketManager(authService: authServise)
        loadFromCache()
        
        #if DEBUG
        loadTestSegments()
        #else
        loadFromCache()
        #endif
    }
    
    
    func startLoadingLines() {
        guard let socketManager = socketManager else { return }
        socketManager.connectSocket(urlString: socketIp)
        socketManager.onLineMessageReceived = { [weak self] segments, center in
            guard let self = self else { return }
            let segmentsData = segments
            let newSegments = parseSegments(from: segmentsData)
            self.updateIfChanged(newSegments: newSegments, center: center)
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
    
    
    func parseSegments(from raw: [[[Double]]]) -> [ShapeSegment] {
        var segments: [ShapeSegment] = []
        
        for segmentData in raw {
            if segmentData.count == 2 {
                let start = CodablePoint(x: CGFloat(segmentData[0][0]), y: CGFloat(segmentData[0][1]))
                let end = CodablePoint(x: CGFloat(segmentData[1][0]), y: CGFloat(segmentData[1][1]))
                segments.append(.line(start: start, end: end))
            }
            if segmentData.count == 3 {
                let start = CodablePoint(x: CGFloat(segmentData[0][0]), y: CGFloat(segmentData[0][1]))
                let end = CodablePoint(x: CGFloat(segmentData[1][0]), y: CGFloat(segmentData[1][1]))
                let radius = CGFloat(segmentData[2][0])
                segments.append(.arc(start: start, end: end, radius: radius))
            }
        }
        return segments
    }
    
    
    func updateIfChanged(newSegments: [ShapeSegment], center: CGPoint, completion: ((Bool) -> Void)? = nil) {
        DispatchQueue.main.async {
            if newSegments != self.segments {
                self.updateLines(newSegments)
                if self.robotPosition != center {
                    self.robotPosition = center
                }
                self.logger.debug("✅ Линии обновлены")
                completion?(true)
            } else {
                self.logger.debug("ℹ️ Линии не изменились — обновление не требуется")
                completion?(false)
            }
        }
        
    }
    
    
    func updateLines(_ newSegments: [ShapeSegment]) {
        segments = newSegments
        saveToCache()
        }
    
    

    func saveToCache() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let cachedSegments = CachedSegments(segments: segments, robotPosition: robotPosition)
        do {
            let data = try encoder.encode(cachedSegments)
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
            let cachedSegments = try decoder.decode(CachedSegments.self, from: data)
            DispatchQueue.main.async {
                self.segments = cachedSegments.segments
                self.robotPosition = cachedSegments.robotPosition
            }
            self.logger.info("✅ Линии загружены из кэша")
        } catch {
            self.logger.info("❌ Ошибка при загрузке линий из кэша: \(error)")
        }
    }

    
    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    
    
    // ⬇️
    #if DEBUG
    func loadTestSegments() {
        let testSegments: [ShapeSegment] = [
            // Прямая 1 (слева направо)
            .line(
                start: CodablePoint(x: 50, y: 100),
                end: CodablePoint(x: 150, y: 100)
            ),
            
            // Дуга 1 (поворот вниз направо)
            .arc(
                start: CodablePoint(x: 150, y: 100),
                end: CodablePoint(x: 200, y: 150),
                radius: 50
            ),
            
            // Прямая 2 (вниз)
            .line(
                start: CodablePoint(x: 200, y: 150),
                end: CodablePoint(x: 200, y: 250)
            ),
            
            // Дуга 2 (поворот налево вниз)
            .arc(
                start: CodablePoint(x: 200, y: 250),
                end: CodablePoint(x: 150, y: 300),
                radius: 50
            ),
            
            // Прямая 3 (влево)
            .line(
                start: CodablePoint(x: 150, y: 300),
                end: CodablePoint(x: 50, y: 300)
            )
        ]
        let testRobotPosition = CGPoint(x: 100, y: 150)

        let testData = CachedSegments(segments: testSegments, robotPosition: testRobotPosition)
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        do {
            let data = try encoder.encode(testData)
            let url = getDocumentsDirectory().appendingPathComponent(cacheFilename)
            try data.write(to: url)
            logger.info("✅ Тестовые сегменты успешно записаны в кэш")
            loadFromCache()
        } catch {
            logger.error("❌ Ошибка при сохранении тестовых сегментов: \(error)")
        }
    }
    #endif
}



extension ShapeSegment {
    static func == (lhs: ShapeSegment, rhs: ShapeSegment) -> Bool {
        switch (lhs, rhs) {
        case let (.line(start1, end1), .line(start2, end2)):
            return start1 == start2 && end1 == end2
        case let (.arc(start1, end1, radius1), .arc(start2, end2, radius2)):
            return start1 == start2 && end1 == end2 && abs(radius1 - radius2) < 0.001
        default:
            return false
        }
    }
    
    static func arcCenter(from p1: CGPoint, to p2: CGPoint, radius: CGFloat) -> (center: CGPoint, clockwise: Bool)? {
        let mid = CGPoint(x: (p1.x + p2.x) / 2, y: (p1.y + p2.y) / 2)
        let dx = p2.x - p1.x
        let dy = p2.y - p1.y
        let d = hypot(dx, dy)
        
        if d > 2 * abs(radius) { return nil }

        let h = sqrt(radius * radius - (d / 2) * (d / 2))
        let perpendicular = CGPoint(x: -dy / d, y: dx / d)
        let direction = radius > 0 ? 1.0 : -1.0

        let center = CGPoint(
            x: mid.x + direction * h * perpendicular.x,
            y: mid.y + direction * h * perpendicular.y
        )

        let clockwise = radius < 0
        return (center, clockwise)
    }
}



extension CodablePoint: Equatable {
    static func == (lhs: CodablePoint, rhs: CodablePoint) -> Bool {
        abs(lhs.x - rhs.x) < 0.001 && abs(lhs.y - rhs.y) < 0.001
    }
}



