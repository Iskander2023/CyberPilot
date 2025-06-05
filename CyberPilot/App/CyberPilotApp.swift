//
//  Robot_ControllerApp.swift
//  Robot_Controller
//
//  Created by Aleksandr Chumakov on 20/01/25.
//
import SwiftUI

@main
struct Robot_ControllerApp: App {
    @StateObject private var container = AppContainer()


    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(container.authService)
                .environmentObject(container.alertManager)
                .environmentObject(container.mapManager)
                .environmentObject(container.lineStore)
                .environmentObject(container.socketController)
                .environmentObject(container.socketManager)
                .environmentObject(container.touchController)
                .environmentObject(container.bluetoothManager)
                
        }
    }
}

