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
    @StateObject private var mapManager = MapManager()
    
    private let mapUpdateTime: TimeInterval = 10.0
    private let logger = CustomLogger(logLevel: .info, includeMetadata: false)
    var localIp: String = "http://localhost:8000/map.yaml"
    var noLocalIp: String = "http://192.168.0.201:8000/map.yaml"
    var mapApdateTime: Double = 5
    
    init(stateManager: RobotManager) {
        self.stateManager = stateManager
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
        .onAppear {
            // Загрузка из кэша
            self.mapManager.map = mapManager.map
            
            // Периодическая загрузка с сервера
            Timer.scheduledTimer(withTimeInterval: mapApdateTime, repeats: true) { _ in
                mapManager.downloadMap(from: localIp) { success in
                    if success {
                        logger.info("✅ Карта обновлена и сохранена")
                        mapManager.saveToCache()
                    } else {
                        logger.info("❌ Ошибка загрузки карты")
                    }
                }
            }
        }
    }
}

