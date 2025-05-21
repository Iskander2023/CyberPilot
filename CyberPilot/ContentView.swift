//
//  ContetntView.swift
//  Robot_Controller
//
//  Created by Aleksandr Chumakov on 20/01/25.
//

import SwiftUI
import CoreData


struct ContentView: View {
    @State private var selectedTab = 0
    @ObservedObject var stateManager: RobotManager
    @StateObject private var mapManager: MapManager
    @StateObject private var lineStore: LineStore
    private let logger = CustomLogger(logLevel: .info, includeMetadata: false)
    
    
    init(stateManager: RobotManager) {
        self.stateManager = stateManager
        self._mapManager = StateObject(wrappedValue: MapManager(robotManager: stateManager))
        self._lineStore = StateObject(wrappedValue: LineStore(robotManager: stateManager))
      
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
            TabView(selection: $selectedTab) {
                SocketView(stateManager: stateManager)
                    .tabItem {
                        Label("Socket", systemImage: "wifi")
                    }
                    .tag(0)
                BluetoothView(stateManager: stateManager)
                    .tabItem {
                        Label("Bluetooth", systemImage: "antenna.radiowaves.left.and.right")
                    }
                    .tag(1)
                MapView(map: mapManager.map)
                    .tabItem {
                        Label("Map", systemImage: "map")
                    }
                    .tag(2)
                LineView(robotManager: stateManager, lineStore: lineStore)
                    .tabItem {
                        Label("Line", systemImage: "point.bottomleft.forward.to.point.topright.scurvepath.fill")
                    }
                    .tag(3)
            }
            .padding(.top, 10)
            .onChange(of: selectedTab) {
                handleTabChange(to: selectedTab)
            }
        }
    }
    
    private func handleTabChange(to tab: Int) {
        if tab == 2 {
            mapManager.startLoadingMap()
            lineStore.stopLoadingLines()
            //mapManager.setupFromLocalFile()
        } else if tab == 3 {
            lineStore.startLoadingLines()
            mapManager.stopLoadingMap()
        } else {
            mapManager.stopLoadingMap()
            lineStore.stopLoadingLines()
        }
    }
}
