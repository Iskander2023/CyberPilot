//
//  LineCacheManager.swift
//  CyberPilot
//
//  Created by Aleksandr Chumakov on 27/05/25.
//

import Foundation


class LineCacheManager {
    private let logger = CustomLogger(logLevel: .info, includeMetadata: false)
    let cacheFilename = "cached_segments.json"
    
    
    func saveToCache(segments: [ShapeSegment], robotPosition: CGPoint?) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let cachedSegments = CachedSegments(segments: segments, robotPosition: robotPosition)
        do {
            let data = try encoder.encode(cachedSegments)
            let url = getDocumentsDirectory().appendingPathComponent(cacheFilename)
            try data.write(to: url)
        } catch {
            self.logger.error("❌ Ошибка при сохранении линий: \(error)")
        }
    }
       

    func loadFromCache() -> CachedSegments? {
        let url = getDocumentsDirectory().appendingPathComponent(cacheFilename)
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            self.logger.info("✅ Линии загружены из кэша")
            return try decoder.decode(CachedSegments.self, from: data)
        } catch {
            self.logger.error("❌ Ошибка при загрузке линий из кэша: \(error)")
            return nil
        }
    }
    
    func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
}
