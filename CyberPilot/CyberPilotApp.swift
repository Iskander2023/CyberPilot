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


    var body: some Scene {
        WindowGroup {
            ContentView(stateManager: stateManager)
        }
    }
}

