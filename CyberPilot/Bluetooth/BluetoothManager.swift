//
//  BluetoothManager.swift
//  CyberPilot
//
//  Created by Aleksandr Chumakov on 20/01/25.
//

import Foundation
import CoreBluetooth


class BluetoothManager: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {
 
    @Published var discoveredDevices: [PeripheralDevice] = []
    @Published var connectedPeripheral: CBPeripheral?
    @Published var characteristicValue: String = ""
    @Published var isScanning: Bool = false
    @Published var connectionStatus: String = "Не подключено"
    @Published var receivedData: [String] = []
    @Published var wifiConnectionStatus: String = ""

   
    private var centralManager: CBCentralManager!
    private var targetCharacteristic: CBCharacteristic?
    private var readCharacteristics: [CBCharacteristic] = []
    private var notifyCharacteristics: [CBCharacteristic] = []
    private var writeCharacteristics: [CBCharacteristic] = []
    private var jsonDataBuffer = Data()
    private var networkConnectionStatus = ""
    private let logger = CustomLogger(logLevel: .info, includeMetadata: false)

    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }

 
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            startScanning()
        case .poweredOff:
            logger.info("Bluetooth выключен.")
            connectionStatus = "Bluetooth выключен"
        case .unsupported:
            logger.info("Устройство не поддерживает Bluetooth.")
            connectionStatus = "Bluetooth не поддерживается"
        default:
            logger.info("Неизвестное состояние Bluetooth.")
            connectionStatus = "Неизвестное состояние Bluetooth"
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        guard let deviceName = peripheral.name else { return }
        let deviceUUID = peripheral.identifier

        if !discoveredDevices.contains(where: { $0.uuid == deviceUUID }) {
            let newDevice = PeripheralDevice(peripheral: peripheral, name: deviceName, rssi: RSSI.intValue, uuid: deviceUUID)
            DispatchQueue.main.async {
                self.discoveredDevices.append(newDevice)
            }
        }
    }

    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        logger.info("Успешно подключено к \(peripheral.name ?? "Неизвестное устройство")")
        connectionStatus = "Подключено к \(peripheral.name ?? "Неизвестное устройство")"
        connectedPeripheral = peripheral
        peripheral.delegate = self
        peripheral.discoverServices(nil)
    }

    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        if let error = error {
            logger.info("Ошибка подключения: \(error.localizedDescription)")
            connectionStatus = "Ошибка подключения"
        }
    }

    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        logger.info("Отключено от \(peripheral.name ?? "Неизвестное устройство")")
        connectionStatus = "Не подключено"
        connectedPeripheral = nil
    }


    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            logger.info("Ошибка при обнаружении сервисов: \(error.localizedDescription)")
            return
        }

        guard let services = peripheral.services else { return }
        for service in services {
            logger.info("Найден сервис: \(service.uuid)")
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }

    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error = error {
            logger.info("Ошибка при обнаружении характеристик: \(error.localizedDescription)")
            return
        }

        guard let characteristics = service.characteristics else { return }
        for characteristic in characteristics {
            logger.info("Найдена характеристика: \(characteristic.uuid)")
            if characteristic.properties.contains(.read) {
                logger.info("Чтение данных из характеристики \(characteristic.uuid)")
                peripheral.readValue(for: characteristic)
                readCharacteristics.append(characteristic)
            }
            if characteristic.properties.contains(.notify) {
                logger.info("Подписка на уведомления для характеристики \(characteristic.uuid)")
                peripheral.setNotifyValue(true, for: characteristic)
                notifyCharacteristics.append(characteristic)
            }
            if characteristic.properties.contains(.write) {
                logger.info("Характеристика \(characteristic.uuid) поддерживает запись")
                writeCharacteristics.append(characteristic)
                targetCharacteristic = characteristic
                    if characteristic.uuid == CBUUID(string: "FFE1") {
                        targetCharacteristic = characteristic
                    }
            }
        }
    }

    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard characteristic.uuid == CBUUID(string: "FFE1"),
              let chunk = characteristic.value,
              let receivedString = String(data: chunk, encoding: .utf8) else { return }

        logger.info("Получено: \(receivedString)")

        DispatchQueue.main.async {
            // Проверяем, если устройство уже подключено к Wi-Fi
            if receivedString.starts(with: "The device is connected to the network:") {
                let networkName = receivedString
                    .replacingOccurrences(of: "The device is connected to the network: ", with: "")
                    .trimmingCharacters(in: .whitespaces)
                
                self.wifiConnectionStatus = "Robot connected to network: \(networkName)"
                self.receivedData = [] // Очищаем список Wi-Fi сетей
                self.jsonDataBuffer.removeAll() // Очищаем буфер
                return
            }

            // Добавляем новый фрагмент в буфер
            self.jsonDataBuffer.append(chunk)

            // Преобразуем буфер в строку для проверки окончания JSON
            if let jsonString = String(data: self.jsonDataBuffer, encoding: .utf8),
               jsonString.contains("}") {

                // Проверяем, является ли JSON валидным перед парсингом
                if let jsonData = jsonString.data(using: .utf8),
                   let _ = try? JSONSerialization.jsonObject(with: jsonData) {

                    do {
                        let decoder = JSONDecoder()
                        let response = try decoder.decode(WiFiNetworkResponse.self, from: jsonData)
                        self.logger.info("Получено: \(response)")

                        self.wifiConnectionStatus = ""  // Убираем статус "Подключено"
                        self.receivedData = response.wifi_networks
                        self.logger.info("Полный список WiFi сетей: \(response.wifi_networks)")
                        self.jsonDataBuffer.removeAll() // Очищаем буфер после успешного парсинга

                    } catch {
                        self.logger.info("Ошибка при разборе JSON: \(error.localizedDescription)")
                    }
                } else {
                    self.logger.info("JSON поврежден, ожидаем оставшиеся фрагменты...")
                }
            } else {
                self.logger.info("Данные пока не полные, ожидаем оставшиеся фрагменты...")
            }
        }
    }


    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            logger.info("Ошибка при записи данных: \(error.localizedDescription)")
            return
        }
        logger.info("Данные успешно записаны в характеристику \(characteristic.uuid).")
    }


    func startScanning() {
        discoveredDevices.removeAll()
        centralManager.scanForPeripherals(withServices: nil, options: nil)
        isScanning = true
        logger.info("Сканирование началось.")
    }

    func stopScanning() {
        centralManager.stopScan()
        isScanning = false
        logger.info("Сканирование остановлено.")
    }
    


    func connect(to peripheral: CBPeripheral) {
        centralManager.connect(peripheral, options: nil)
        logger.info("Подключение к \(peripheral.name ?? "Неизвестное устройство")...")

        // Таймер на отключение, если устройство не подключилось за 10 секунд
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) { [weak self] in
            guard let self = self else { return }
            if self.connectedPeripheral == nil {
                self.centralManager.cancelPeripheralConnection(peripheral)
                self.connectionStatus = "Ошибка: тайм-аут подключения"
                logger.info("Тайм-аут подключения к \(peripheral.name ?? "Неизвестное устройство")")
            }
        }
    }

    
    func disconnect(from peripheral: CBPeripheral) {
        // Очищаем данные при отключении
        receivedData = []
        // Оригинальная логика отключения
        if peripheral.state == .connected {
            centralManager?.cancelPeripheralConnection(peripheral)
        }
        connectedPeripheral = nil
        wifiConnectionStatus = ""
        receivedData = []
    }
    
    func disconnectFromWiFi() {
        guard let peripheral = connectedPeripheral, let characteristic = targetCharacteristic else {
            logger.info("❌ Ошибка: Устройство или характеристика для записи не выбраны.")
            return
        }
        
        // Проверяем, подключено ли устройство
        guard peripheral.state == .connected else {
            logger.info("⚠️ Ошибка: Устройство не подключено по Bluetooth.")
            return
        }
        
        let turnOffCommand: [String: String] = [
            "turn_off_wifi": "disconnected_wifi"
        ]
        
        do {
            // Кодирование JSON в Data
            let disconnectWiFiData = try JSONSerialization.data(withJSONObject: turnOffCommand, options: [])
            
            // Отправка данных по Bluetooth
            peripheral.writeValue(disconnectWiFiData, for: characteristic, type: .withResponse)
            
            logger.info("✅ Отправлена команда на отключение Wi-Fi: \(String(data: disconnectWiFiData, encoding: .utf8) ?? "Ошибка кодирования")")
        } catch {
            logger.info("❌ Ошибка кодирования JSON Wi-Fi данных: \(error.localizedDescription)")
        }
    }

        

    func sendWiFiCredentials(ssid: String, password: String) {
        guard let peripheral = connectedPeripheral, let characteristic = targetCharacteristic else {
            logger.info("Устройство или характеристика для записи не выбраны.")
            return
        }

        // Формирование JSON-объекта
        let credentials: [String: String] = [
            "ssid": ssid,
            "password": password
        ]

        // Кодирование JSON в Data
        guard let jsonData = try? JSONSerialization.data(withJSONObject: credentials, options: []) else {
            logger.info("Ошибка кодирования JSON Wi-Fi данных.")
            return
        }

        // Отправка данных по Bluetooth
        peripheral.writeValue(jsonData, for: characteristic, type: .withResponse)

        logger.info("Отправка Wi-Fi данных в формате JSON: \(String(data: jsonData, encoding: .utf8) ?? "Ошибка кодирования")")
    }

    func writeValue(_ value: String) {
        guard let peripheral = connectedPeripheral, let characteristic = targetCharacteristic else {
            logger.info("Устройство или характеристика для записи не выбраны.")
            return
        }

        guard let data = value.data(using: .utf8) else {
            logger.info("Не удалось преобразовать строку в данные.")
            return
        }

        peripheral.writeValue(data, for: characteristic, type: .withResponse)
        logger.info("Запись данных '\(value)' в характеристику \(characteristic.uuid).")
    }
}



