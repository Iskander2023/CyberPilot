//
//  RobotStateManager.swift
//  Robot_Controller
//
//  Created by Aleksandr Chumakov on 20/01/25.
//

import Foundation


class RobotManager: ObservableObject {
    @Published var userLogin: String = ""
    @Published var isAuthenticated = false
    @Published var isPhoneNumber = false
    
    
    func logout() {
        isAuthenticated = false
        userLogin = ""
    }
}
//    @Published var isAuthenticated = false {
//            didSet {
//                UserDefaults.standard.set(isAuthenticated, forKey: "isAuthenticated")
//                UserDefaults.standard.set(isRobotId, forKey: "isRobotId")
//            }
//        }
//        init() {
//            self.isAuthenticated = UserDefaults.standard.bool(forKey: "isAuthenticated")
//            self.isRobotId = UserDefaults.standard.bool(forKey: "isRobotId")
//        }
//    }
