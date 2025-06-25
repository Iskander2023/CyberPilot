//
//  GenericCacheManager.swift
//  CyberPilot
//
//  Created by Aleksandr Chumakov on 27/05/25.
//

import Foundation

final class GenericCacheManager<T: Codable> {
    private let filename: String
    private let logger = CustomLogger(logLevel: .info, includeMetadata: false)

    init(filename: String) {
        self.filename = filename
    }
    
    
    // сохранение в файл
    func save(_ object: T) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted

        do {
            let data = try encoder.encode(object)
            let url = getDocumentsDirectory().appendingPathComponent(filename)
            try data.write(to: url)
            logger.debug("✅ Объект сохранён в кэш по пути: \(url)")
        } catch {
            logger.error("❌ Ошибка при сохранении объекта в кэш: \(error)")
        }
    }
    
    
    // загрузка из файла
    func load() -> T? {
        let url = getDocumentsDirectory().appendingPathComponent(filename)

        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let object = try decoder.decode(T.self, from: data)
            logger.info("✅ Объект загружен из кэша")
            return object
        } catch {
            logger.error("❌ Ошибка при загрузке объекта из кэша: \(error)")
            return nil
        }
    }

    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
//    func updateIfChanged(current: inout T?, newValue: T, completion: ((Bool) -> Void)? = nil) {
//        if current != newValue {
//            current = newValue
//            save(newValue)
//            completion?(true)
//        } else {
//            completion?(false)
//        }
//    }
}

