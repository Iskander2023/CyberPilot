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
    @StateObject private var viewModel = SocketController()
    @State private var showVideoView = false
    @State private var selectedConnectionType = 0
    @State private var webView: WKWebView? = nil

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            VStack(spacing: 20) {
                Spacer()

                if viewModel.isConnected {
                    WebViewRepresentable(urlString: viewModel.videoURL)
                        .frame(height: 350)
                        .padding(.horizontal, 20)
                }
                    if !viewModel.isConnected {
                        Picker("Connection Type", selection: $selectedConnectionType) {
                            Text("Удалённый сервер").tag(0)
                            Text("Локальная сеть").tag(1)
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal)
                        .onChange(of: selectedConnectionType) {
                            viewModel.connectionTypeChanged(isLocal: selectedConnectionType == 0)
                        }
                        
                        Group {
                            if selectedConnectionType == 0 {
                                TextField("ws://selekpann.tech:2000", text: $viewModel.remoteURL)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                
                            } else {
                                TextField("robot3.local", text: $viewModel.host)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .disableAutocorrection(true)
                            }
                        }
                        .frame(width: 250)
                }
                if viewModel.isConnected {
                    HStack {
                        Button(action: viewModel.disconnect) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 35))
                                .foregroundColor(.red)
                        }
                    }
                } else {
                    Button(action: {
                        viewModel.connect(isLocal: selectedConnectionType == 0)
                    }) {
                        Text("Connect")
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(8)
                    }
                }

                Spacer()
            }
            .padding(.top, 100)

            // 🔴 Индикатор подключения
            HStack {
                Text("R\(viewModel.robotSuffix):")
                    .font(.system(size: 16, weight: .medium))

                Circle()
                    .frame(width: 20, height: 20)
                    .foregroundColor(viewModel.isConnected ? .green : .red)
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)

            // 🔵 Кнопка камеры (только если подключено)
            if viewModel.isConnected {
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

            // ⏳ Загрузка
            if viewModel.isLoading {
                ProgressView()
                    .scaleEffect(1.5)
                    .progressViewStyle(CircularProgressViewStyle(tint: .blue))
            }
        }
        .onReceive(viewModel.$host) { _ in
            viewModel.updateRobotSuffix()
        }
        .alert("Ошибка", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage)
        }
        // 📹 Переход к VideoView
        .sheet(isPresented: $showVideoView) {
            FullScreenVideoView(
                videoURL: viewModel.videoURL,
                commandSender: viewModel.commandSender
            )
        }
    }
}


