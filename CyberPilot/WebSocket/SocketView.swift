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
    @State private var webView: WKWebView? = nil
    @State private var videoFailedToLoad = false
    
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.white.ignoresSafeArea()
                
                let calculatedWidth = geometry.size.width * 0.9
                let calculatedHeight: CGFloat = 300
                
                if videoFailedToLoad {
                    VStack(spacing: 12) {
                        Text("⚠️ Видео недоступно")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        
                    }
                    .frame(maxWidth: calculatedWidth, maxHeight: calculatedHeight)
                    .background(Color.black)
                    .zIndex(1)
                } else {
                    WebView(
                        urlString: controller.videoStreamManager.videoURL,
                        onLoadFailed: {
                            videoFailedToLoad = true
                        }
                    )
                    .frame(height: AppConfig.SocketView.webViewHeight)
                    .padding(.horizontal, AppConfig.SocketView.mainContentPadding)
                    .border(Color.gray, width: 2)
                }
                
                cameraButton
                loadingIndicator
            }
        }
        .onReceive(controller.connectionManager.$socketURL) { _ in
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
    }
    
    
    private var cameraButton: some View {
        Group {
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




//private var mainContent: some View {
//        VStack(spacing: AppConfig.SocketView.mainContentSpacing) {
//
//
//            if controller.connectionManager.isConnected {
//            WebView(urlString: controller.videoStreamManager.videoURL)
//                .frame(height: AppConfig.SocketView.webViewHeight)
//                .padding(.horizontal, AppConfig.SocketView.mainContentPadding)
//            }
//
//            if !controller.connectionManager.isConnected {
//                connectionAddressField
//            }
//
//            connectionButton
//
//
//        }
//    }

//private var connectionAddressField: some View {
//        VStack(alignment: .leading, spacing: 6) {
//            Text("Адрес сервера:")
//                .font(.system(size: 14, weight: .semibold))
//                .foregroundColor(.gray)
//                .padding(.horizontal)
//
//            TextField("Введите адрес сервера", text: $controller.connectionManager.remoteURL)
//                .padding()
//                .background(Color(UIColor.secondarySystemBackground))
//                .cornerRadius(10)
//                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
//                .padding(.horizontal)
//                .font(.system(size: 16, weight: .medium))
//                .autocapitalization(.none)
//                .disableAutocorrection(true)
//        }
//    }
//
//
//    private var connectionButton: some View {
//        Group {
//            if controller.connectionManager.isConnected {
//                disconnectButton
//            } else {
//                connectButton
//            }
//        }
//    }
//
//
//    private var connectButton: some View {
//        Button(action: {
//            controller.connectionManager.connect()
//        }) {
//            Text("Connect")
//                .foregroundColor(AppConfig.SocketView.connectButtonForegroundColor)
//                .padding()
//                .background(AppConfig.SocketView.connectButtonBackgroundColor)
//                .cornerRadius(AppConfig.SocketView.connectButtonCornerRadius)
//        }
//    }
//
//    private var disconnectButton: some View {
//        HStack {
//            Button(action: controller.connectionManager.disconnect) {
//                Image(systemName: AppConfig.SocketView.disconnectButtonSystemName)
//                    .font(.system(size: AppConfig.SocketView.disconnectButtonFont))
//                    .foregroundColor(AppConfig.SocketView.disconnectButtonForegroundColor)
//            }
//        }
//    }
