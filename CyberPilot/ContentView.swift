//
//  ContetntView.swift
//  Robot_Controller
//
//  Created by Admin on 20/01/25.
//

import SwiftUI
import CoreData


struct ContentView: View {
    @ObservedObject var stateManager: RobotManager
    
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
    
    @State private var loadedMap: OccupancyGridMap? = nil
    
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
                MapView(map: loadedMap)
                    .tabItem {
                        Label("Map", systemImage: "map")
                    }
            }
            .padding(.top, 10)
        }
        .onAppear {
            if let path = Bundle.main.path(forResource: "map", ofType: "yaml") {
                self.loadedMap = loadOccupancyGridMap(from: path)
            } else {
                print("Файл не найден в Bundle")
            }
        }
    }
}
