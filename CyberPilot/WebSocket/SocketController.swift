//  SSHViewController.swift
//  SSHConnector
//  Created by Aleksandr Chumakov on 18.03.2025.


import UIKit
import os


class SocketController: UIViewController, SocketDelegate {
    let logger = CustomLogger(logLevel: .info, includeMetadata: false)
    let prefix = "ws://"
    let serverCommand = ServerRegisterCommand()
    var webView: WebVideoView!
    var socketManager: SocketManager!
    var stateManager: RobotManager!
    
    var isConnected = false
    
    var defaulLocaltHost = "robot3.local"
    var defaultRemoteHost = "ws://selekpann.tech:2000"
    var robotIP: String?
    
    private var commandSender: CommandSender!
    private var connectionType: ConnectionType!
    private var commandTimer: Timer?
    

    let hostTextField = UITextField()
    
    let connectButton = UIButton(type: .system)
    let disconnectButton = UIButton(type: .system)
    let controlPanel = UIStackView()
    
    let forwardButton = UIButton(type: .system)
    let backButton = UIButton(type: .system)
    let leftButton = UIButton(type: .system)
    let rightButton = UIButton(type: .system)
    let stopTheMovementButton = UIButton(type: .system)
    
    let activityIndicator = UIActivityIndicatorView(style: .large)
    
    let statusLabel = UILabel()
    let statusIndicator = UIView()
    
    
    private let connectionTypeSegmentedControl = UISegmentedControl(items: ["Локальная сеть", "Удалённый сервер"])
    private let remoteURLTextField = UITextField()

    
    override func viewDidLoad() {
        super.viewDidLoad()
        socketManager = SocketManager()
        socketManager.delegate = self
        commandSender = CommandSender(socketManager: socketManager)
        setupUI()
        setupWebView()
        updateUI()
        NotificationCenter.default.addObserver(self, selector: #selector(appDidEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
    }
    
    
    init(stateManager: RobotManager) {
        self.stateManager = stateManager
        super.init(nibName: nil, bundle: nil)
    }
    

    func didResolveRobotIP(_ ip: String) {
        print("Получен IP: \(ip)")
        robotIP = ip
    }
    
    
    func didFailToResolveIP(error: String?) {
        print("Ошибка: \(error ?? "Unknown")")
    }
    
    @objc func appDidEnterBackground() {
        disconnectFromRobot()
        self.logger.info("⚠️ Приложение перешло в фон")
    }
    
    
    func socketManager(_ manager: SocketManager, didReceiveResponse response: String) {
        self.logger.info("Message from server: \(response)")
        self.showAlert(title: "Message", message: response)
    }

    
    func socketManager(_ manager: SocketManager, didUpdateConnectionStatus isConnected: Bool) {
        DispatchQueue.main.async {
            self.isConnected = isConnected
            
            if isConnected {
                self.logger.info("Подключение к сокету ✅")
                self.webView.loadVideoStream(urlString: "https://selekpann.tech:8889/camera_robot_4")
                self.activityIndicator.stopAnimating()
                self.updateConnectionStatus(isConnected: true)
            } else {
                self.logger.info("Подключение к сокету ❌")
                self.activityIndicator.stopAnimating()
                self.updateConnectionStatus(isConnected: false)
                self.hide_input_fields_for_parameters(true)
            }
            self.updateUI()
        }
    }
    
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    func hide_input_fields_for_parameters(_ isEnabled: Bool) {
        hostTextField.isEnabled = isEnabled
        connectButton.isEnabled = isEnabled
        remoteURLTextField.isEnabled = isEnabled
    }
    
    
    @objc func textFieldDidChange() {
            updateStatusLabel()
        }
        
    
    private func updateStatusLabel() {
        let host = robotIP ?? ""
        let lastDigit = getLastDigit(from: host)
        statusLabel.text = "R\(lastDigit):"
    }
    
    
    private func getLastDigit(from host: String) -> String {
        let parts = host.split(separator: ".")
        if let lastPart = parts.last {
            if let lastChar = lastPart.last, lastChar.isNumber {
                return String(lastChar)
            }
        }
        return ""
    }
    
    
    private func getPort(from host: String) -> String? {
        let parts = host.split(separator: ".")
        guard let lastPart = parts.last else { return nil }
        let startPort = "8"
        return startPort + String(lastPart)
    }
    
    
    @objc private func connectionTypeChanged() {
        let isLocal = connectionTypeSegmentedControl.selectedSegmentIndex == 0
        hostTextField.isHidden = !isLocal
        remoteURLTextField.isHidden = isLocal
    }
    
    private func setupUI() {
        view.backgroundColor = .white
        let stackView = UIStackView()
        
       connectionTypeSegmentedControl.selectedSegmentIndex = 0
       connectionTypeSegmentedControl.addTarget(self, action: #selector(connectionTypeChanged), for: .valueChanged)
       
       remoteURLTextField.placeholder = defaultRemoteHost

        hostTextField.text = defaulLocaltHost
        hostTextField.borderStyle = .roundedRect
        hostTextField.autocapitalizationType = .none


        connectButton.setTitle("Connect", for: .normal)
        connectButton.addTarget(self, action: #selector(connectToRobot), for: .touchUpInside)

        disconnectButton.addTarget(self, action: #selector(disconnectFromRobot), for: .touchUpInside)

        statusIndicator.backgroundColor = .red
        statusIndicator.layer.cornerRadius = 10
        statusIndicator.translatesAutoresizingMaskIntoConstraints = false

        activityIndicator.translatesAutoresizingMaskIntoConstraints = false

        
        
        statusLabel.text = "R:"
        statusLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        hostTextField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)

        stackView.axis = .vertical
        stackView.spacing = 15
        stackView.alignment = .center
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        stackView.addArrangedSubview(connectionTypeSegmentedControl)
        stackView.addArrangedSubview(remoteURLTextField)
        
        stackView.addArrangedSubview(hostTextField)
        stackView.addArrangedSubview(connectButton)
        stackView.addArrangedSubview(controlPanel)
        
        setupControlButtons()

        disconnectButton.setTitle("✖️", for: .normal)
        disconnectButton.titleLabel?.font = UIFont.systemFont(ofSize: 35)
        disconnectButton.setTitleColor(.white, for: .normal)
        disconnectButton.clipsToBounds = true
        disconnectButton.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(statusIndicator)
        view.addSubview(activityIndicator)
        view.addSubview(statusLabel)
        view.addSubview(stackView)
        view.addSubview(controlPanel)
        view.addSubview(disconnectButton)

        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            hostTextField.widthAnchor.constraint(equalToConstant: 250),

            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.topAnchor.constraint(equalTo: hostTextField.bottomAnchor, constant: 20),

            statusLabel.trailingAnchor.constraint(equalTo: statusIndicator.leadingAnchor, constant: -8),
            statusLabel.centerYAnchor.constraint(equalTo: statusIndicator.centerYAnchor),

            statusIndicator.widthAnchor.constraint(equalToConstant: 20),
            statusIndicator.heightAnchor.constraint(equalToConstant: 20),
            statusIndicator.topAnchor.constraint(equalTo: view.topAnchor, constant: 10),
            statusIndicator.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            disconnectButton.leadingAnchor.constraint(equalTo: statusIndicator.trailingAnchor, constant: -30),
            disconnectButton.topAnchor.constraint(equalTo: statusIndicator.bottomAnchor, constant: 20),
            disconnectButton.widthAnchor.constraint(equalToConstant: 40),
            disconnectButton.heightAnchor.constraint(equalToConstant: 40),
        ])
            }
    
    private func setupWebView() {
        webView = WebVideoView()
        webView.backgroundColor = .black
        webView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(webView)
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 100), // Отступ сверху
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20), // Отступ слева
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20), // Отступ справа
            webView.heightAnchor.constraint(equalToConstant: 350),

            controlPanel.topAnchor.constraint(equalTo: webView.bottomAnchor, constant: 10),
            controlPanel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        ])
    }
    
    
    private func updateUI() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let isConnected = self.socketManager.isLocalConnected
            self.hostTextField.isHidden = isConnected
            self.connectButton.isHidden = isConnected
            self.disconnectButton.isHidden = !isConnected
            self.webView.isHidden = !isConnected
            self.controlPanel.isHidden = !isConnected
            
        }
    }
    
    
    @objc private func connectToRobot() {
        self.hide_input_fields_for_parameters(false)
        activityIndicator.startAnimating()
        let isLocal = connectionTypeSegmentedControl.selectedSegmentIndex == 0
        if isLocal {
            connectToLocalRobot()
        } else {
            connectToRemoteServer()
            self.updateStatusLabel()
        }
    }

    
    func connectToLocalRobot() {
        if let hostname = hostTextField.text, !hostname.isEmpty {
            socketManager.startResolvingIP(for: hostname)
        } else {
            print("Поле ввода пустое, IP не будет разрешён")
        }
        let host = hostTextField.text ?? defaulLocaltHost
        let port = getPort(from: robotIP ?? "") ?? ""
        let urlString = "\(prefix)\(robotIP ?? host):\(port)"
        socketManager.connectSocket(urlString: urlString)
        self.updateStatusLabel()
        self.logger.info("Попытка подключения к \(urlString)")
    }
    
    
    func connectToRemoteServer() {
        socketManager.connectSocket(urlString: defaultRemoteHost)
        self.logger.info("Подключение к удалённому серверу: \(defaultRemoteHost)")
        socketManager.sendJSONCommand(serverCommand.registerServerMsg)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.socketManager.sendJSONCommand(self.serverCommand.listMsg)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.socketManager.sendJSONCommand(self.serverCommand.registerOperatorMsg)
                self.logger.info("Зарегистрирован как оператор для robot1")
            }
        }
    }
    
    @objc private func disconnectFromRobot() {
        self.hide_input_fields_for_parameters(true)
        NotificationCenter.default.removeObserver(self)
        self.updateConnectionStatus(isConnected: false)
        self.webView.stopVideo()
        self.commandTimer?.invalidate()
        self.commandTimer = nil
        socketManager.disconnectSocket()
        self.updateUI()
    }
    
    
    func updateConnectionStatus(isConnected: Bool) {
            statusIndicator.backgroundColor = isConnected ? .green : .red
        }

    
    func startRepeatingCommand(action: @escaping () -> Void) {
        commandTimer?.invalidate()
        commandTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { _ in
            action()
        }
    }

    
    @objc func stopSendingCommand() {
        commandTimer?.invalidate()
        commandTimer = nil
        stopMove()
    }
    
    
    func showAlert(title: String, message: String) {
        DispatchQueue.main.async {
            if let presentedViewController = self.presentedViewController, presentedViewController is UIAlertController {
                presentedViewController.dismiss(animated: false) {
                    self.presentAlert(title: title, message: message)
                }
            } else {
                self.presentAlert(title: title, message: message)
            }
        }
    }

    private func presentAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    @objc func startMovingForward() { startRepeatingCommand { self.moveForward() } }
    @objc func startMovingBackward() { startRepeatingCommand { self.moveBackward() } }
    @objc func startTurningLeft() { startRepeatingCommand { self.turnLeft() } }
    @objc func startTurningRight() { startRepeatingCommand { self.turnRight() } }
    
    
    @objc func moveForward() {commandSender.moveForward()}
    @objc func moveBackward() {commandSender.moveBackward()}
    @objc func turnLeft() {commandSender.turnLeft()}
    @objc func turnRight() {commandSender.turnRight()}
    @objc func stopMove() {commandSender.stopTheMovement()}

    
    
    func setupControlButtons() {
        let buttonSize: CGFloat = 80

        func addHoldAction(for button: UIButton, startAction: Selector, stopAction: Selector) {
            button.addTarget(self, action: startAction, for: .touchDown)         // Запуск при нажатии
            button.addTarget(self, action: stopAction, for: .touchUpInside)      // Остановка при отпускании внутри кнопки
            button.addTarget(self, action: stopAction, for: .touchUpOutside)     // Остановка при уходе пальца с кнопки
            button.addTarget(self, action: stopAction, for: .touchCancel)
        }


        func styleButton(_ button: UIButton, systemImage: String) {
            button.setTitle("", for: .normal)
            let image = UIImage(systemName: systemImage)
            button.setImage(image, for: .normal)
            button.tintColor = .black
            button.layer.cornerRadius = buttonSize / 2
            button.layer.borderWidth = 2
            button.layer.borderColor = UIColor.black.cgColor
            button.translatesAutoresizingMaskIntoConstraints = false
            button.widthAnchor.constraint(equalToConstant: buttonSize).isActive = true
            button.heightAnchor.constraint(equalToConstant: buttonSize).isActive = true
        }

        styleButton(forwardButton, systemImage: "arrow.up")
        styleButton(backButton, systemImage: "arrow.down")
        styleButton(leftButton, systemImage: "arrow.left")
        styleButton(rightButton, systemImage: "arrow.right")

        addHoldAction(for: forwardButton, startAction: #selector(startMovingForward), stopAction: #selector(stopSendingCommand))
        addHoldAction(for: backButton, startAction: #selector(startMovingBackward), stopAction: #selector(stopSendingCommand))
        addHoldAction(for: leftButton, startAction: #selector(startTurningLeft), stopAction: #selector(stopSendingCommand))
        addHoldAction(for: rightButton, startAction: #selector(startTurningRight), stopAction: #selector(stopSendingCommand))

        stopTheMovementButton.addTarget(self, action: #selector(stopMove), for: .touchUpInside)

        let row1 = UIStackView(arrangedSubviews: [UIView(), forwardButton, UIView()])
        row1.axis = .horizontal
        row1.distribution = .equalSpacing

        let row2 = UIStackView(arrangedSubviews: [leftButton, UIView(), rightButton])
        row2.axis = .horizontal
        row2.spacing = 30

        let row3 = UIStackView(arrangedSubviews: [UIView(), backButton, UIView()])
        row3.axis = .horizontal
        row3.distribution = .equalSpacing

        controlPanel.axis = .vertical
        controlPanel.spacing = -10
        controlPanel.alignment = .center
        controlPanel.addArrangedSubview(row1)
        controlPanel.addArrangedSubview(row2)
        controlPanel.addArrangedSubview(row3)

        }
    }


enum ConnectionType {
    case localNetwork(urlString: String)  // Локальная сеть (robot.local)
    case remoteServer(url: String)       // Удалённый сервер (wss://example.com)
}
