//
//  CyberPilot.swift
//  SocketView
//
//  Created by Aleksandr Chumakov on 18.03.2025.
//
import SwiftUI
import WebKit


struct SocketView: View {
    @EnvironmentObject var controller: SocketController
    @State private var showVideoView = false
    @State private var selectedConnectionType = 0
    @State private var webView: WKWebView? = nil
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            mainContent
                .padding(.top, AppConfig.SocketView.mainContentPadding)
            
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
    
    
    private var mainContent: some View {
        VStack(spacing: AppConfig.SocketView.mainContentSpacing) {
            Spacer()
            
            if controller.connectionManager.isConnected {
                WebView(urlString: controller.videoStreamManager.videoURL)
                    .frame(height: AppConfig.SocketView.webViewHeight)
                    .padding(.horizontal, AppConfig.SocketView.mainContentPadding)
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
                TextField(AppConfig.Addresses.serverAddress, text: $controller.connectionManager.remoteURL)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            } else {
                TextField(AppConfig.Addresses.localAddress, text: $controller.connectionManager.host)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .disableAutocorrection(true)
            }
        }
        .frame(width: AppConfig.SocketView.connectionAddressFrame)
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
                .foregroundColor(AppConfig.SocketView.connectButtonForegroundColor)
                .padding()
                .background(AppConfig.SocketView.connectButtonBackgroundColor)
                .cornerRadius(AppConfig.SocketView.connectButtonCornerRadius)
        }
    }
    
    private var disconnectButton: some View {
        HStack {
            Button(action: controller.connectionManager.disconnect) {
                Image(systemName: AppConfig.SocketView.disconnectButtonSystemName)
                    .font(.system(size: AppConfig.SocketView.disconnectButtonFont))
                    .foregroundColor(AppConfig.SocketView.disconnectButtonForegroundColor)
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
                .font(.system(size: AppConfig.SocketView.connectionIndicatorTextSize, weight: .medium))
            
            Circle()
                .frame(width: AppConfig.SocketView.connectionIndicatorCircleWidth, height: AppConfig.SocketView.connectionIndicatorCircleHeight)
                .foregroundColor(controller.connectionManager.isConnected ? AppConfig.SocketView.connectionIndicatorConnectColor : AppConfig.SocketView.connectionIndicatorDisconnectColor)
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
                            Image(systemName: AppConfig.SocketView.cameraButtonSystemName)
                                .foregroundColor(AppConfig.SocketView.cameraButtonForegroundColor)
                                .font(.system(size: AppConfig.SocketView.cameraButtonikonSize))
                                .padding()
                                .background(AppConfig.SocketView.cameraButtonBackground.opacity(AppConfig.SocketView.cameraButtonOpacity))
                                .clipShape(Circle())
                        }
                        .padding(.top, AppConfig.SocketView.cameraButtonPaddingTop)
                        .padding(.leading, AppConfig.SocketView.cameraButtonPaddingLeading)
                        
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

