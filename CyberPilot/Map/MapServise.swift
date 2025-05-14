//
//  MapLoader.swift
//  CyberPilot
//
//  Created by Aleksandr Chumakov on 12/05/25.
//

import Foundation
import Yams

private let logger = CustomLogger(logLevel: .info, includeMetadata: false)


func loadOccupancyGridMap(from url: URL) -> OccupancyGridMap? {
    guard let yamlString = try? String(contentsOf: url),
          let parsed = try? Yams.load(yaml: yamlString) as? [String: Any],
          let info = parsed["info"] as? [String: Any],
          let width = info["width"] as? Int,
          let height = info["height"] as? Int,
          let resolution = info["resolution"] as? Double,
          let data = info["data"] as? [Int] else {
        logger.info("Ошибка разбора карты")
        return nil
    }

    guard data.count == width * height else {
        logger.info("Размер данных не совпадает с размерами карты.")
        return nil
    }

    return OccupancyGridMap(width: width, height: height, resolution: resolution, data: data)
}


func downloadMap(from urlString: String, completion: @escaping (OccupancyGridMap?) -> Void) {
    guard let url = URL(string: urlString) else { return }
    URLSession.shared.dataTask(with: url) { data, _, _ in
        guard let data = data, let string = String(data: data, encoding: .utf8) else {
            completion(nil)
            return
        }

        if let parsed = try? Yams.load(yaml: string) as? [String: Any],
           let info = parsed["info"] as? [String: Any],
           let width = info["width"] as? Int,
           let height = info["height"] as? Int,
           let resolution = info["resolution"] as? Double,
           let data = info["data"] as? [Int] {
            DispatchQueue.main.async {
                completion(OccupancyGridMap(width: width, height: height, resolution: resolution, data: data))
            }
        } else {
            completion(nil)
        }
    }.resume()
}

func saveMap(_ map: OccupancyGridMap, to filename: String) {
    let encoder = JSONEncoder()
    encoder.outputFormatting = .prettyPrinted

    do {
        let data = try encoder.encode(map)
        let url = getDocumentsDirectory().appendingPathComponent(filename)
        try data.write(to: url)
        print("✅ Карта сохранена по пути: \(url)")
    } catch {
        print("❌ Ошибка при сохранении карты: \(error)")
    }
}


func loadMap(from filename: String) -> OccupancyGridMap? {
    let url = getDocumentsDirectory().appendingPathComponent(filename)

    do {
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        let map = try decoder.decode(OccupancyGridMap.self, from: data)
        print("✅ Карта загружена")
        return map
    } catch {
        print("❌ Ошибка при загрузке карты: \(error)")
        return nil
    }
}


func getDocumentsDirectory() -> URL {
    FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
}


