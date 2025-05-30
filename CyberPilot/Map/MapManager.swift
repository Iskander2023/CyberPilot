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
    var localIp: String = "http://127.0.0.1:8000/map.yaml"
    var socketIp: String = "ws://172.16.17.79:8765"
    var noLocalIp: String = "http://192.168.0.201:8000/map.yaml"

    
    
    init(authService: AuthService) {
        map = mapCacheManager.load()
        socketListener = SocketListener(authService: authService, socketIp: "ws://172.16.17.79:8765")
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
        downloadMapFromLocalFile(from: localIp)
        setupRefreshTimer()
    }
    
    
    func setupRefreshTimer() {
        timerCancellable?.cancel()
        timerCancellable = Timer
            .publish(every: mapUpdateTime, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.downloadMapFromLocalFile(from: self.localIp)
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
                    self.logger.info("✅ Карта не изменилась — пропускаем кэширование")
                    completion?(false)
                }
            }
        }.resume()
    }
}
