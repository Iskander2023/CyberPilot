//
//  VideoStreamManager.swift
//  CyberPilot
//
//  Created by Aleksandr Chumakov on 7/05/25.
//
import Combine


final class VideoStreamManager: ObservableObject, TokenUpdatable {
    @Published var prefixUrl = "https://selekpann.tech:8889/mystream/?token="
    @Published var videoURL = ""
    var token: String?
    var cancellables = Set<AnyCancellable>()
    
    init(robotManager: AuthService) {
        setupTokenBinding(from: robotManager)
    }
    
    func updateToken(_ newToken: String?) {
        self.token = newToken
        if let token = newToken {
            self.videoURL = "\(prefixUrl)\(token)"
            print("video ==== \(self.videoURL)")
        } else {
            self.videoURL = ""
            
        }
    }
}
