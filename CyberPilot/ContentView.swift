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
            }
            .padding(.top, 10)
        }
    }
}
