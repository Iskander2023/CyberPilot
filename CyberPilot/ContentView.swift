//
//  ContetntView.swift
//  Robot_Controller
//
//  Created by Aleksandr Chumakov on 20/01/25.
//

import SwiftUI
import CoreData


struct ContentView: View {
    @ObservedObject var stateManager: RobotManager
    @StateObject private var mapManager: MapManager
    private let logger = CustomLogger(logLevel: .info, includeMetadata: false)
    
    
    init(stateManager: RobotManager) {
        self.stateManager = stateManager
        self._mapManager = StateObject(wrappedValue: MapManager(robotManager: stateManager))
    }
    
    var body: some View {
        NavigationView {
            VStack {
                if stateManager.isAuthenticated == false {
                    LoginView(stateManager: stateManager)
                } else {
                    mainContentView
                }
            }
            
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Text(stateManager.userLogin)
                        .font(.system(size: 16))
                        .foregroundColor(.primary)
                }
                
                ToolbarItem {
                    Button(action: {
                        stateManager.logout()
                    }) {
                        Text("Выйти")
                            .font(.system(size: 16))
                            .foregroundColor(.red)
                    }
                    .disabled(!stateManager.isAuthenticated)
                    .opacity(stateManager.isAuthenticated ? 1.0 : 0)
                }
            }
        }
    }
    
    
    
    private var mainContentView: some View {
        VStack {
            TabView {
                SocketView(stateManager: stateManager)
                    .tabItem {
                        Label("Socket", systemImage: "wifi")
                    }
                BluetoothView(stateManager: stateManager)
                    .tabItem {
                        Label("Bluetooth", systemImage: "antenna.radiowaves.left.and.right")
                    }
                MapView(map: mapManager.map)
                    .tabItem {
                        Label("Map", systemImage: "map")
                    }
            }
            .padding(.top, 10)
        }
    }
}
