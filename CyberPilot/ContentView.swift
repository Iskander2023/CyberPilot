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
    @EnvironmentObject var connectionManager: ConnectionManager

    @State private var selectedTab = 0
    
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
                // Левая сторона: логин + чат-кнопка
                ToolbarItem(placement: .navigationBarLeading) {
                        Text(authService.userLogin)
                            .font(.system(size: 14))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }

                ToolbarItem(placement: .navigationBarLeading) {
                    ChatButton()
                        .disabled(!authService.isAuthenticated || !connectionManager.isConnected)
                        .opacity(authService.isAuthenticated ? 1.0 : 0.0)
                        .padding(.leading, 20)
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    ConnectionIndicator()
                        .foregroundColor(connectionManager.isConnected ? AppConfig.SocketView.connectionIndicatorConnectColor : AppConfig.SocketView.connectionIndicatorDisconnectColor)
                        .disabled(!authService.isAuthenticated)
                        .opacity(authService.isAuthenticated ? 1.0 : 0.0)
                        .padding(.leading, 20) // <-- отступ от предыдущего ToolbarItem
                }

                // Правая сторона: кнопка "Выйти"
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        authService.logout()
                    }) {
                        Text("Выйти")
                            .font(.system(size: 16))
                            .foregroundColor(.red)
                    }
                    .disabled(!authService.isAuthenticated)
                    .opacity(authService.isAuthenticated ? 1.0 : 0.0)
                }
            }

        }
    }
    
    private var mainContentView: some View {
        VStack {
            TabView(selection: $selectedTab) {
                
                RobotSelectionView()
                    .tabItem {
                        Image("robotminimono30") 
                            .resizable()
                            .scaledToFit()
                            .background(Color.gray)
                            .cornerRadius(10)
                        Text("Robots")
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


