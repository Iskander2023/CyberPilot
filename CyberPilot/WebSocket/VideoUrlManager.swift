//
//  VideoStreamManager.swift
//  CyberPilot
//
//  Created by Aleksandr Chumakov on 7/05/25.
//
import SwiftUI
import Combine


final class VideoUrlManager: ObservableObject, TokenUpdatable {
    @Published var videoURL = ""
    var cameraUrl = ""
    var token: String?
    let logger = CustomLogger(logLevel: .info, includeMetadata: false)
    var cancellables = Set<AnyCancellable>()
    
    init(authService: AuthService) {
        setupTokenBinding(from: authService)
    }
    
    
    func setCameraUrl(_ camera_url: String) {
        logger.debug("Установлен cameraUrl: \(cameraUrl)")
        self.cameraUrl = camera_url
        updateCameraUrl()
        
    }
    
    
    func updateCameraUrl() {
        guard let token = self.token, !cameraUrl.isEmpty else {
            logger.warn("cameraUrl или token не установлены")
            return
        }
        guard var components = URLComponents(string: cameraUrl) else {
            logger.error("Невозможно создать URLComponents из cameraUrl")
            return
        }
        components.queryItems = [URLQueryItem(name: "token", value: token)]
        
        if let url = components.url?.absoluteString {
            videoURL = url
            logger.info("Сформирован URL подключения к камере: \(videoURL)")
        }
    }

    
    
    func updateToken(_ newToken: String?) {
        self.token = newToken
        }
    }
