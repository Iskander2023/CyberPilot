//
//  IndoorMapEditor.swift
////  CyberPilot
////
////  Created by Aleksandr Chumakov on 7/05/25.
////
import Foundation
import Yams
import Combine

final class MapManager: ObservableObject {
    @Published var map: OccupancyGridMap?
    var authService: AuthService
    private var socketManager: SocketManager?
    private let logger = CustomLogger(logLevel: .info, includeMetadata: false)
    private let cacheFilename = "cached_map.json"
    private let mapUpdateTime: TimeInterval = 10
    private var timerCancellable: AnyCancellable?
    var localIp: String = "http://127.0.0.1:8000/map.yaml"
    var socketIp: String = "ws://172.16.17.79:8765"
    var noLocalIp: String = "http://192.168.0.201:8000/map.yaml"
    var mapApdateTime: Double = 5
    
    

    init(authService: AuthService) {
        self.authService = authService
        map = loadMapFromCache()
        socketManager = SocketManager(authService: authService)
    }
    

    func updateMap(with dataArray: [Int], len: Int,  completion: ((Bool) -> Void)? = nil) {
        let width = len
        let height = len
        let resolution = 0.1 // можно вынести в переменную или параметр
        guard dataArray.count == width * height else {
            logger.info("❌ Размер массива не совпадает с размерами карты.")
            return
        }
        let newMap = OccupancyGridMap(width: width, height: height, resolution: resolution, data: dataArray)
        DispatchQueue.main.async {
            if self.map != newMap {
                //self.logger.info("🔄 Карта изменилась — сохраняем в кэш")
                self.map = newMap
                self.saveToCache()
                completion?(true)
            } else {
                //self.logger.info("✅ Карта не изменилась — пропускаем кэширование")
                completion?(false)
            }
        }
    }
    
    func setupFromLocalFile() {
        logger.info("✅ setupFromLocalFile вызван")
        downloadMapFromLocalFile(from: localIp)
        setupRefreshTimer()
    }
    
    
    func setupRefreshTimer() {
        timerCancellable?.cancel()
        timerCancellable = Timer
            .publish(every: mapApdateTime, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.downloadMapFromLocalFile(from: self.localIp)
            }
    }
    
    
    func startLoadingMap() {
        guard let socketManager = socketManager else { return }
        socketManager.connectSocket(urlString: socketIp)
        socketManager.onMapArrayReceived = { [weak self] array, len in
            self?.updateMap(with: array, len: len)
        }
        // Проверка соединения через 2 секунд
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            guard let self = self else { return }
            
            if !socketManager.isConnected {
                socketManager.disconnectSocket()
                self.logger.error("Сокет не подключён через 5 секунд — соединение прервано")
            } else {
                self.logger.info("Сокет успешно подключён")
            }
        }
    }
    
    func stopLoadingMap() {
        timerCancellable?.cancel()
        if let socketManager = socketManager, socketManager.isConnected {
                socketManager.disconnectSocket()
                logger.info("Загрузка карты остановлена и сокет отключён")
            } else {
                logger.info("Загрузка карты остановлена (сокет уже был отключён)")
            }
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
                        self.saveToCache()
                        completion?(true)
                    } else {
                        self.logger.info("✅ Карта не изменилась — пропускаем кэширование")
                        completion?(false)
                    }
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
            logger.debug("✅ Карта сохранена в кэш по пути: \(url)")
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



////Загрузка из локального YAML не используется!!!
//func loadFromYAMLFile(url: URL) -> Bool {
//    guard let yamlString = try? String(contentsOf: url),
//          let parsed = try? Yams.load(yaml: yamlString) as? [String: Any],
//          let info = parsed["info"] as? [String: Any],
//          let width = info["width"] as? Int,
//          let height = info["height"] as? Int,
//          let resolution = info["resolution"] as? Double,
//          let data = info["data"] as? [Int] else {
//        logger.info("Ошибка разбора карты из YAML")
//        return false
//    }
//
//    guard data.count == width * height else {
//        logger.info("Размер данных не совпадает с размерами карты.")
//        return false
//    }
//    self.map = OccupancyGridMap(width: width, height: height, resolution: resolution, data: data)
//    return true
//}
