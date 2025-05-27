//
//  LineStore.swift
//  CyberPilot
//
//  Created by Aleksandr Chumakov on 16/05/25.
//

import SwiftUI
import Combine

class LineStore: ObservableObject {
    private let dataManager = LineDataManager()
    private let cacheManager = LineCacheManager()
    private let socketService: LineSocketService
    private let logger = CustomLogger(logLevel: .info, includeMetadata: false)
    
    
    var segments: [ShapeSegment] { dataManager.segments }
    var robotPosition: CGPoint? { dataManager.robotPosition }
    
    init (authService: AuthService) {
        self.socketService = LineSocketService(authServise: authService)
        loadInitialData()
    }
    
    func setupSocketHandlers() {
        socketService.onLineMessageReceived = { [weak self] segments, center in
            guard let self = self else { return }
            let newSegments = dataManager.parseSegments(from: segments)
            self.updateIfChanged(newSegments: newSegments, center: center)
        }
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
    
    
    func updateIfChanged(newSegments: [ShapeSegment],
                         center: CGPoint,
                         completion: ((Bool) -> Void)? = nil) {
        DispatchQueue.main.async {
            var didUpdate = false
            if newSegments != self.segments {
                self.dataManager.updateLines(newSegments)
                didUpdate = true
                self.logger.debug("✅ Линии обновлены")
            } else {
                self.logger.debug("ℹ️ Линии не изменились — обновление не требуется")
            }
            if self.dataManager.robotPosition != center {
                self.dataManager.updateRobotPosition(center)
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
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        do {
            let data = try encoder.encode(testData)
            let url = cacheManager.getDocumentsDirectory().appendingPathComponent(cacheManager.cacheFilename)
            try data.write(to: url)
            logger.info("✅ Тестовые сегменты успешно записаны в кэш")
            if let cached = cacheManager.loadFromCache() {
                    dataManager.updateLines(cached.segments)
                    dataManager.updateRobotPosition(cached.robotPosition)
                }
        } catch {
            logger.error("❌ Ошибка при сохранении тестовых сегментов: \(error)")
        }
    }
    #endif
}

