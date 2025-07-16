//
//  ContentView.swift
//  CyberPilot
//
//  Created by Aleksandr Chumakov on 20/01/25.
//

import SwiftUI
import CoreData


struct ContentView: View {
    @EnvironmentObject private var authService: AuthService
    @EnvironmentObject private var mapManager: MapManager
    @EnvironmentObject private var lineStore: LineManager

    @State private var selectedTab = 0
    @State private var scale: CGFloat = 1.0
    private let logger = CustomLogger(logLevel: .info, includeMetadata: false)
    
    var body: some View {
        NavigationView {
            VStack {
                if authService.isAuthenticated == false {
                    LoginView()
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
                
                ToolbarItem(placement: .navigationBarLeading) {
                    ChatButton()
                        .disabled(!authService.isAuthenticated)
                        .opacity(authService.isAuthenticated ? 1.0 : 0)
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
                    .modifier(
                            CombinedTouchModifier(
                                minScale: 0.5,
                                maxScale: 3.0
                            )
                        )
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
            mapManager.setupFromLocalFile() // загрузка с локального файла
//            mapManager.startLoadingMap() // загрузка через сокет
            lineStore.stopLoadingLines()
        } else if tab == 3 {
            lineStore.startLoadingLines()
            mapManager.stopLoadingMap()
        } else {
            mapManager.stopLoadingMap()
            lineStore.stopLoadingLines()
        }
    }
}


