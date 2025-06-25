//
//  MapManager.swift
////  CyberPilot
////
////  Created by Aleksandr Chumakov on 7/05/25.
////
import Foundation
import Yams
import Combine



class MapManager: ObservableObject {
    @Published var map: OccupancyGridMap?
    let mapCacheManager = GenericCacheManager<OccupancyGridMap>(filename: AppConfig.Cached.mapFilename)
    private let socketListener: SocketListener
    private let logger = CustomLogger(logLevel: .info, includeMetadata: false)
    private var timerCancellable: AnyCancellable?

    
    
    init(authService: AuthService) {
        map = mapCacheManager.load()
        socketListener = SocketListener(authService: authService, socketIp: AppConfig.Cached.mapFilename)
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
    
    
    func setupFromLocalFile() {
        logger.info(AppConfig.MapManagerMessage.loadingFromLocalFile)
        downloadMapFromLocalFile(from: AppConfig.MapManager.noLocalIp)
        //setupRefreshTimer() // закомичено для тестов
        
    }
    
    
    func setupRefreshTimer() {
        timerCancellable?.cancel()
        timerCancellable = Timer
            .publish(every: AppConfig.MapManager.mapUpdateTime, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.downloadMapFromLocalFile(from: AppConfig.MapManager.noLocalIp)
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
                    self.logger.info(AppConfig.MapManagerMessage.theMapHasChanged)
                    self.map = newMap
                    self.mapCacheManager.save(newMap)
                    completion?(true)
                } else {
                    self.logger.info(AppConfig.MapManagerMessage.theMapHasNotChanged)
                    completion?(false)
                }
            }
        }.resume()
    }
    
    
    func updateIfChanged(with dataArray: [Int], len: Int,  completion: ((Bool) -> Void)? = nil) {
        let width = len
        let height = len
        guard dataArray.count == width * height else {
            logger.error(AppConfig.MapManagerMessage.arrayDoesNotMatchMap)
            return
        }
        let newMap = OccupancyGridMap(width: width, height: height, resolution: AppConfig.MapManager.resolution, data: dataArray)
        DispatchQueue.main.async {
            if self.map != newMap {
                self.logger.debug(AppConfig.MapManagerMessage.theMapHasChanged)
                self.map = newMap
                self.mapCacheManager.save(newMap)
                completion?(true)
            } else {
                self.logger.debug(AppConfig.MapManagerMessage.theMapHasNotChanged)
                completion?(false)
            }
        }
    }
    
    
}
