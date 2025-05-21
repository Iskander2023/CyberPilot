//
//  CyberPilot.swift
//  SocketView
//
//  Created by Aleksandr Chumakov on 18.03.2025.
//
import SwiftUI
import WebKit


struct SocketView: View {
    @ObservedObject var stateManager: RobotManager
    @StateObject private var controller: SocketController
    
    // Локальные состояния представления
    @State private var showVideoView = false
    @State private var selectedConnectionType = 0
    @State private var webView: WKWebView? = nil
    
    init(stateManager: RobotManager) {
        self._stateManager = ObservedObject(initialValue: stateManager)
        self._controller = StateObject(wrappedValue: SocketController(robotManager: stateManager))
    }

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            mainContent
                .padding(.top, 100)
            
            connectionIndicator
            
            cameraButton
            
            loadingIndicator
        }
        .onReceive(controller.connectionManager.$host) { _ in
            controller.updateRobotSuffix()
        }
        .alert("Ошибка", isPresented: $controller.errorManager.showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(controller.errorManager.errorMessage)
        }
        .sheet(isPresented: $showVideoView) {
            VideoView(
                videoURL: controller.videoStreamManager.videoURL,
                commandSender: controller.commandSender
            )
        }
        .sheet(isPresented: $controller.robotListManager.showRobotPicker) {
            RobotSelectionView(
                robots: controller.robotListManager.availableRobots
            ) { selectedRobot in
                controller.robotListManager.registerAsOperator(for: selectedRobot)
            }
        }
    }
    
    // MARK: - Subviews
    
    private var mainContent: some View {
        VStack(spacing: 20) {
            Spacer()
            
            if controller.connectionManager.isConnected {
                WebView(urlString: controller.videoStreamManager.videoURL)
                    .frame(height: 350)
                    .padding(.horizontal, 20)
            }
            
            if !controller.connectionManager.isConnected {
                connectionTypePicker
                connectionAddressField
            }
            
            connectionButton
            
            if !controller.connectionManager.isConnected {
                testConnectionButton
            }
            
            Spacer()
        }
    }
    
    private var connectionTypePicker: some View {
        Picker("Connection Type", selection: $selectedConnectionType) {
            Text("Удалённый сервер").tag(0)
            Text("Локальная сеть").tag(1)
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
        .onChange(of: selectedConnectionType) {
            controller.connectionManager.connectionTypeChanged(isLocal: selectedConnectionType == 1)
        }
    }
    
    private var connectionAddressField: some View {
        Group {
            if selectedConnectionType == 0 {
                TextField("ws://selekpann.tech:2000", text: $controller.connectionManager.remoteURL)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            } else {
                TextField("robot3.local", text: $controller.connectionManager.host)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .disableAutocorrection(true)
            }
        }
        .frame(width: 250)
    }
    
    private var connectionButton: some View {
        Group {
            if controller.connectionManager.isConnected {
                disconnectButton
            } else {
                connectButton
            }
        }
    }
    
    private var connectButton: some View {
        Button(action: {
            controller.connectionManager.connect(isLocal: selectedConnectionType == 1)
        }) {
            Text("Connect")
                .foregroundColor(.white)
                .padding()
                .background(Color.blue)
                .cornerRadius(8)
        }
    }
    
    private var disconnectButton: some View {
        HStack {
            Button(action: controller.connectionManager.disconnect) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 35))
                    .foregroundColor(.red)
            }
        }
    }
    
    private var testConnectionButton: some View {
        Button("Симулировать подключение") {
            controller.simulateRobotListResponse()
        }
        .foregroundColor(.white)
        .padding()
        .background(Color.orange)
        .cornerRadius(8)
    }
    
    private var connectionIndicator: some View {
        HStack {
            Text("R\(controller.robotSuffix):")
                .font(.system(size: 16, weight: .medium))
            
            Circle()
                .frame(width: 20, height: 20)
                .foregroundColor(controller.connectionManager.isConnected ? .green : .red)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
    }
    
    private var cameraButton: some View {
        Group {
            if controller.connectionManager.isConnected {
                VStack {
                    HStack {
                        Button(action: {
                            showVideoView = true
                        }) {
                            Image(systemName: "camera.fill")
                                .foregroundColor(.black)
                                .padding()
                                .background(Color.white.opacity(0.8))
                                .clipShape(Circle())
                        }
                        .padding(.top, 16)
                        .padding(.leading, 16)
                        
                        Spacer()
                    }
                    Spacer()
                }
            }
        }
    }
    
    private var loadingIndicator: some View {
        Group {
            if controller.isLoading {
                ProgressView()
                    .scaleEffect(1.5)
                    .progressViewStyle(CircularProgressViewStyle(tint: .blue))
            }
        }
    }
}

