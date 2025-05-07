//
//  VideoStreamManager.swift
//  CyberPilot
//
//  Created by Aleksandr Chumakov on 7/05/25.
//
import Combine


final class VideoStreamManager: ObservableObject {
    @Published var prefixUrl = "https://selekpann.tech:8889/mystream/?token="
    @Published var videoURL = ""
    @Published var token: String?
    
    private var cancellables = Set<AnyCancellable>()
    
    init(robotManager: RobotManager) {
        setupTokenSubscription(robotManager: robotManager)
    }
    
    private func setupTokenSubscription(robotManager: RobotManager) {
        robotManager.$token
            .sink { [weak self] newToken in
                guard let self = self, let token = newToken else { return }
                self.videoURL = "\(self.prefixUrl)\(token)"
            }
            .store(in: &cancellables)
    }
}
