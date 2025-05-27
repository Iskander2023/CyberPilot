//
//  ContetntView.swift
//  CyberPilot
//
//  Created by Aleksandr Chumakov on 20/01/25.
//

import SwiftUI
import CoreData


struct ContentView: View {
    @EnvironmentObject private var authService: AuthService
    @EnvironmentObject private var mapManager: MapManager
    @EnvironmentObject private var lineStore: LineStore
    @State private var selectedTab = 0
    @State private var scale: CGFloat = 1.0
    private let logger = CustomLogger(logLevel: .info, includeMetadata: false)
    
    var body: some View {
        NavigationView {
            VStack {
                if authService.isAuthenticated == false {
                    LoginView(authService: authService)
                } else {
                    mainContentView
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Text(authService.userLogin)
                        .font(.system(size: 16))
                        .foregroundColor(.primary)
                }
                
                ToolbarItem {
                    Button(action: {
                        authService.logout()
                    }) {
                        Text("Выйти")
                            .font(.system(size: 16))
                            .foregroundColor(.red)
                    }
                    .disabled(!authService.isAuthenticated)
                    .opacity(authService.isAuthenticated ? 1.0 : 0)
                }
            }
        }
    }
    
    private var mainContentView: some View {
        VStack {
            TabView(selection: $selectedTab) {
                SocketView()
                    .tabItem {
                        Label("Socket", systemImage: "wifi")
                    }
                    .tag(0)
                
                BluetoothView()
                    .tabItem {
                        Label("Bluetooth", systemImage: "antenna.radiowaves.left.and.right")
                    }
                    .tag(1)
                
                MapView()
                    .tabItem {
                        Label("Map", systemImage: "map")
                    }
                    //.withMagnification()
                    .tag(2)
                    
                
                LineView()
                    .tabItem {
                        Label("Line", systemImage: "point.bottomleft.forward.to.point.topright.scurvepath.fill")
                    }
                    .withMagnification()
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
        } else if tab == 3 {
            lineStore.setupSocketHandlers()
            mapManager.stopLoadingMap()
        } else {
            mapManager.stopLoadingMap()
            lineStore.stopLoadingLines()
        }
    }
}


