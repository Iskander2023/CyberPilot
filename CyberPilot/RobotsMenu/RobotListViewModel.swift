//
//  RobotListViewModel.swift
//  CyberPilot
//
//  Created by Admin on 21/07/25.
//

import SwiftUI


/// класс который получает список роботов
class RobotListViewModel: ObservableObject {
    @Published var robots: [Robot] = []


    private var token: String {
        KeychainService.shared.getAccessToken() ?? ""
    }

    func fetchRobots() {
        APIService.shared.fetchRobots(token: self.token) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let fetchedRobots):
                    self.robots = fetchedRobots
                case .failure(let error):
                    print("Ошибка загрузки роботов: \(error.localizedDescription)")
                }
            }
        }
    }
}
