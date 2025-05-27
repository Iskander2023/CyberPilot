//
//  LineStore.swift
//  CyberPilot
//
//  Created by Aleksandr Chumakov on 16/05/25.
//

import SwiftUI
import Combine

class LineStore: ObservableObject {
    private let socketService: LineSocketService
    private let logger = CustomLogger(logLevel: .info, includeMetadata: false)
    private let segmentsCacheManager = GenericCacheManager<CachedSegments>(filename: "cached_segments.json")
    @Published var segments: [ShapeSegment] = []
    @Published var robotPosition: CGPoint? = nil
    
    init (authService: AuthService) {
        self.socketService = LineSocketService(authService: authService)
        loadInitialData() // тестовый режим
    }
    
    
    func setupSocketHandlers() {
        startLoadingLines()
        socketService.onLineMessageReceived = { [weak self] segments, center in
            guard let self = self else { return }
            let newSegments = parseSegments(from: segments)
            DispatchQueue.main.async {
                self.updateIfChanged(newSegments: newSegments, center: center)
            }
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
    
    
    private func loadInitialData() {
        #if DEBUG
            loadTestSegments()
        #else
            if let cached = cacheManager.loadFromCache() {
                dataManager.updateLines(cached.segments)
                dataManager.updateRobotPosition(cached.robotPosition)
            }
        #endif
    }
    
    func startLoadingLines() {
        socketService.startSocket()
    }
    
    func stopLoadingLines() {
        socketService.stopSocket()
        
    }
    
    func updateLines(_ newSegments: [ShapeSegment]) {
        segments = newSegments
    }
    
    
    
    func updateRobotPosition(_ newPosition: CGPoint?) {
        robotPosition = newPosition
    }
    
    
    func updateIfChanged(newSegments: [ShapeSegment],
                         center: CGPoint,
                         completion: ((Bool) -> Void)? = nil) {
        DispatchQueue.main.async {
            var didUpdate = false
            if newSegments != self.segments {
                self.updateLines(newSegments)
                didUpdate = true
                self.logger.debug("✅ Линии обновлены")
            } else {
                self.logger.debug("ℹ️ Линии не изменились — обновление не требуется")
            }
            if self.robotPosition != center {
                self.updateRobotPosition(center)
                didUpdate = true
                self.logger.debug("✅ Позиция робота обновлена")
            }
            completion?(didUpdate)
        }
    }
    
    
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
        segmentsCacheManager.save(testData)
        logger.info("✅ Тестовые сегменты успешно записаны в кэш")
        if let cached = segmentsCacheManager.load() {
                updateLines(cached.segments)
                updateRobotPosition(cached.robotPosition)
            }
        
    }
    #endif
}


