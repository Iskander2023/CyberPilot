//
//  IndoorMapEditor.swift
////  CyberPilot
////
////  Created by Aleksandr Chumakov on 7/05/25.
////
import Foundation
import Yams

final class MapManager: ObservableObject {
    private let logger = CustomLogger(logLevel: .info, includeMetadata: false)
    private let cacheFilename = "cached_map.json"
    @Published var map: OccupancyGridMap?


    //Инициализация
    init() {
        map = loadMapFromCache()
    }

    //Загрузка из локального YAML
    func loadFromYAMLFile(url: URL) -> Bool {
        guard let yamlString = try? String(contentsOf: url),
              let parsed = try? Yams.load(yaml: yamlString) as? [String: Any],
              let info = parsed["info"] as? [String: Any],
              let width = info["width"] as? Int,
              let height = info["height"] as? Int,
              let resolution = info["resolution"] as? Double,
              let data = info["data"] as? [Int] else {
            logger.info("Ошибка разбора карты из YAML")
            return false
        }

        guard data.count == width * height else {
            logger.info("Размер данных не совпадает с размерами карты.")
            return false
        }
        self.map = OccupancyGridMap(width: width, height: height, resolution: resolution, data: data)
        return true
    }

    // Загрузка из сети
    func downloadMap(from urlString: String, completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: urlString) else {
            completion(false)
            return
        }
        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data,
                  let string = String(data: data, encoding: .utf8),
                  let parsed = try? Yams.load(yaml: string) as? [String: Any],
                  let info = parsed["info"] as? [String: Any],
                  let width = info["width"] as? Int,
                  let height = info["height"] as? Int,
                  let resolution = info["resolution"] as? Double,
                  let data = info["data"] as? [Int] else {
                DispatchQueue.main.async {
                    completion(false)
                }
                return
            }
            DispatchQueue.main.async {
                self.map = OccupancyGridMap(width: width, height: height, resolution: resolution, data: data)
                completion(true)
            }
        }.resume()
    }

    //Сохранение и загрузка карты
    func saveToCache() {
        guard let map = map else { return }
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted

        do {
            let data = try encoder.encode(map)
            let url = getDocumentsDirectory().appendingPathComponent(cacheFilename)
            try data.write(to: url)
            logger.info("✅ Карта сохранена в кэш по пути: \(url)")
        } catch {
            logger.info("❌ Ошибка при сохранении карты: \(error)")
        }
    }
     // загрузка из кэша
    private func loadMapFromCache() -> OccupancyGridMap? {
        let url = getDocumentsDirectory().appendingPathComponent(cacheFilename)

        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let map = try decoder.decode(OccupancyGridMap.self, from: data)
            logger.info("✅ Карта загружена из кэша")
            return map
        } catch {
            logger.info("❌ Ошибка при загрузке карты из кэша: \(error)")
            return nil
        }
    }

    // путь сохранения в файлменеджере
    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
}
