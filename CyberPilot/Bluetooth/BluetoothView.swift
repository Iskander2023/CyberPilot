//
//  BluetoothView.swift
//  Robot_Controller
//
//  Created by AleksandrChumakov on 20/01/25.
//

import SwiftUI
import CoreData

struct BluetoothView: View {
    @ObservedObject var stateManager: RobotManager
    @ObservedObject var bluetoothManager = BluetoothManager()
    
    @State private var selectedNetwork: String?
    @State private var isShowingPasswordPrompt = false


    var body: some View {
        NavigationView {
                VStack(spacing: 16) {
                    bluetoothSection()
                    
                    // Показываем секцию Wi-Fi только при подключении
                    if bluetoothManager.connectedPeripheral != nil {
                        wifiNetworksSection()
                    }
                    
                    Spacer()
                }
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        connectionStatusHeader()
                    }
                    
                    ToolbarItem(placement: .navigationBarTrailing) {
                        HStack {
                            connectionStatusButton()
                        }
                    }
                }
            }
        .onAppear(perform: bluetoothManager.startScanning)
        .onDisappear(perform: bluetoothManager.stopScanning)
        .sheet(isPresented: $isShowingPasswordPrompt) {
            if let network = selectedNetwork {
                PasswordInputView(networkName: network) { ssid, password in
                    bluetoothManager.sendWiFiCredentials(ssid: ssid, password: password)
                }
            } else {
                VStack {
                    Text("Ошибка выбора сети")
                        .font(.headline)
                    Text("Пожалуйста, выберите сеть заново")
                        .foregroundColor(.secondary)
                }
            }
        }
    }
        
    
        private func connectionStatusHeader() -> some View {
            Group {
                if let peripheral = bluetoothManager.connectedPeripheral {
                    VStack(alignment: .center) {
                        Text(peripheral.name ?? "Устройство")
                            .font(.headline)
                        Text("Статус: Подключено")
                            .font(.subheadline)
                            .foregroundColor(.green)
                    }
                } else {
                    Text("Поиск устройств...")
                        .font(.headline)
                        .foregroundColor(.gray)
                }
            }
        }
        
        private func connectionStatusButton() -> some View {
            Group {
                if let peripheral = bluetoothManager.connectedPeripheral {
                    Button {
                        bluetoothManager.disconnect(from: peripheral)
                    } label: {
                        Text("Отключить")
                            .foregroundColor(.red)
                    }
                } else {
                    EmptyView()
                }
            }
        }
    
    
    private func bluetoothSection() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Bluetooth устройства")
                .font(.headline)
                .padding(.horizontal)
            
            List {
                ForEach(bluetoothManager.discoveredDevices, id: \.id) { device in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(device.name)
                                .fontWeight(.medium)
                            Text(device.uuid.uuidString)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                        
                        if bluetoothManager.connectedPeripheral?.identifier == device.peripheral.identifier {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        } else {
                            connectButton(for: device)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .frame(height: 200)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
            .padding(.horizontal)
        }
    }
    
    
    private func wifiNetworksSection() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Доступные Wi-Fi сети")
                .font(.headline)
                .padding(.horizontal)

            Group {
                if !bluetoothManager.wifiConnectionStatus.isEmpty {
                    // Если подключено к сети — показываем статус и кнопку отключения
                    VStack {
                        HStack {
                            Image(systemName: "wifi")
                                .foregroundColor(.green)
                            Text(bluetoothManager.wifiConnectionStatus)
                                .font(.subheadline)
                                .foregroundColor(.green)
                        }
                        .padding()
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(8)

                        Button(action: {
                            bluetoothManager.disconnectFromWiFi()
                        }) {
                            Text("Отключиться")
                                .font(.subheadline)
                                .foregroundColor(.red)
                                .padding(8)
                                .frame(maxWidth: .infinity)
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(8)
                        }
                        .padding(.top, 8)
                    }
                    .padding(.horizontal)
                } else {
                    if bluetoothManager.receivedData.isEmpty {
                        emptyStateView()
                    } else {
                        networksListView()
                    }
                }
            }
            .frame(height: 200)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
            .padding(.horizontal)
        }
    }



    
    private func connectButton(for device: PeripheralDevice) -> some View {
        Button {
            bluetoothManager.connect(to: device.peripheral)
        } label: {
            Text("Подключить")
                .font(.subheadline)
                .padding(8)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
    
    private func networksListView() -> some View {
        List {
            ForEach(Array(bluetoothManager.receivedData.enumerated()), id: \.offset) { index, network in
                HStack {
                    Image(systemName: "wifi")
                        .foregroundColor(.blue)

                    Text(network)
                        .font(.subheadline)

                    Spacer()

                    if network.contains("5G") {
                        Text("5G")
                            .font(.caption)
                            .padding(4)
                            .background(Color.green.opacity(0.2))
                            .cornerRadius(4)
                    }
                }
                .padding(.vertical, 8)
                .onTapGesture {
                    selectedNetwork = network
                    print("Выбрана сеть: \(selectedNetwork ?? "nil")")
                }
            }
        }
        .onChange(of: selectedNetwork) {
            if selectedNetwork != nil {
                isShowingPasswordPrompt = true
            }
        }
        .onDisappear {
            selectedNetwork = nil
        }
    }


    
    private func emptyStateView() -> some View {
        VStack {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 40))
                .padding(.bottom, 8)
            Text("Сети не найдены")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func refreshButton() -> some View {
        Button {
            bluetoothManager.receivedData = []
            // Здесь можно добавить запрос на обновление списка сетей
        } label: {
            Image(systemName: "arrow.clockwise")
                .foregroundColor(.blue)
        }
    }
    
    private func connectionStatusOverlay() -> some View {
        Group {
            if bluetoothManager.connectionStatus != "Не подключено" {
                Text(bluetoothManager.connectionStatus)
                    .font(.caption)
                    .padding(8)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                    .transition(.opacity)
                    .padding(.top, 8)
            }
        }
    }
}


struct PasswordInputView: View {
    let networkName: String
    var onConnect: (String, String) -> Void
    
    @State private var password: String = ""
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                headerSection()
                inputSection()
                actionsSection()
            }
            .navigationTitle("Подключение к Wi-Fi")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func headerSection() -> some View {
        VStack {
            HStack {
                Image(systemName: "wifi")
                Text(networkName)
                    .font(.title2)
                    .bold()
            }
            .padding(.top)
            
            Divider()
        }
    }
    
    private func inputSection() -> some View {
        VStack(alignment: .leading) {
            Text("Введите пароль для сети:")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            SecureField("Пароль", text: $password)
                .textFieldStyle(.roundedBorder)
                .textContentType(.password)
                .submitLabel(.done)
        }
        .padding()
    }
    
    private func actionsSection() -> some View {
        HStack {
            Button("Отмена") {
                dismiss()
            }
            .foregroundColor(.red)
            
            Spacer()
            
            Button("Подключить") {
                onConnect(networkName, password)
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .disabled(password.isEmpty)
        }
        .padding()
    }
}
