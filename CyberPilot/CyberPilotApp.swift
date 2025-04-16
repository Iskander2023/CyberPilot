//
//  Robot_ControllerApp.swift
//  Robot_Controller
//
//  Created by Admin on 20/01/25.
//
import SwiftUI

@main
struct Robot_ControllerApp: App {
    @StateObject private var stateManager = RobotManager()
    @StateObject private var alertManager = AlertManager()


    var body: some Scene {
        WindowGroup {
            ContentView(stateManager: stateManager)
                .environmentObject(alertManager) 
        }
    }
}

