//
//  VideoViewController.swift
//  CyberPilot
//
//  Created by Aleksandr Chumakov on 16/04/25.
//

import UIKit
import WebKit


class VideoViewController: UIViewController {
    var videoURL: String?
    var webView: WKWebView!
    var socketController: SocketController?
    var commandSender: CommandSender?
    
    private var gestureView: TouchPadView! // тачпад
    private var directionOverlayLeft: DirectionOverlayView! // перспектива левая
    private var directionOverlayRight: DirectionOverlayView!
    

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupWebView()
        loadVideoStream()
        setupCloseButton()
        //setupControlButtons()
    }

    private func setupWebView() {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        config.allowsAirPlayForMediaPlayback = true
        
        webView = WKWebView(frame: .zero, configuration: config)
        webView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(webView)
        
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.topAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
        // 1. Сначала создаем directionOverlay (чтобы он был под жестами)
        directionOverlayLeft = DirectionOverlayView()
        directionOverlayLeft.backgroundColor = .clear
        directionOverlayLeft.isUserInteractionEnabled = false
        directionOverlayLeft.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(directionOverlayLeft)
        
        NSLayoutConstraint.activate([
            directionOverlayLeft.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: -100),
            directionOverlayLeft.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: 150),
            directionOverlayLeft.widthAnchor.constraint(equalToConstant: 200), // нужная ширина
            directionOverlayLeft.heightAnchor.constraint(equalToConstant: 200) // нужная высота
        ])
        
        directionOverlayRight = DirectionOverlayView()
        directionOverlayRight.backgroundColor = .clear
        directionOverlayRight.isUserInteractionEnabled = false
        directionOverlayRight.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(directionOverlayRight)
        
        NSLayoutConstraint.activate([
            directionOverlayRight.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: 100),
            directionOverlayRight.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: 150),
            directionOverlayRight.widthAnchor.constraint(equalToConstant: 200), // нужная ширина
            directionOverlayRight.heightAnchor.constraint(equalToConstant: 200) // нужная высота
        ])
        
        // 2. Затем создаем gestureView (он будет перехватывать тачи)
        gestureView = TouchPadView()
        gestureView.backgroundColor = .clear
        gestureView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(gestureView)
        
        NSLayoutConstraint.activate([
            gestureView.topAnchor.constraint(equalTo: view.topAnchor),
            gestureView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            gestureView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            gestureView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
        // 3. Настраиваем обработчики жестов
        
        gestureView.onAngleChanged = { [weak self] angle in
            guard let self else { return }
            let flags = self.controlFlags(for: angle)
            self.commandSender?.moveForward(isPressed: flags["forward"] ?? false)
            self.commandSender?.moveBackward(isPressed: flags["backward"] ?? false)
            self.commandSender?.turnLeft(isPressed: flags["left"] ?? false)
            self.commandSender?.turnRight(isPressed: flags["right"] ?? false)
        }
        
        
        gestureView.onStop = { [weak self] in
            guard let self else { return }
            
            self.commandSender?.moveForward(isPressed: false)
            self.commandSender?.moveBackward(isPressed: false)
            self.commandSender?.turnLeft(isPressed: false)
            self.commandSender?.turnRight(isPressed: false)
        }
        
        gestureView.onRotationDirectionChanged = { [weak self] direction in
            guard let self else { return }
            
            switch direction {
            case .clockwise:
                print("👉 Робот поворачивает направо")
                self.commandSender?.turnRight(isPressed: true)
                self.commandSender?.turnLeft(isPressed: false)
            case .counterClockwise:
                print("👈 Робот поворачивает налево")
                self.commandSender?.turnLeft(isPressed: true)
                self.commandSender?.turnRight(isPressed: false)
            }
        }
    }

    
    func controlFlags(for angle: CGFloat) -> [String: Bool] {
        let degrees = angle * 180 / .pi
        print("angle", degrees)
        var flags = [
            "forward": false,
            "backward": false,
            "left": false,
            "right": false
        ]
        
        switch degrees {
        case 337.5..<360, 0..<22.5:
            flags["right"] = true
        case 22.5..<67.5:
            flags["right"] = true
            flags["backward"] = true
        case 67.5..<112.5:
            flags["backward"] = true
        case 112.5..<157.5:
            flags["left"] = true
            flags["backward"] = true
        case 157.5..<202.5:
            flags["left"] = true
        case 202.5..<247.5:
            flags["left"] = true
            flags["forward"] = true
        case 247.5..<292.5:
            flags["forward"] = true
        case 292.5..<337.5:
            flags["right"] = true
            flags["forward"] = true
        default:
            break
        }

        
        return flags
    }


    private func loadVideoStream() {
        guard let urlString = videoURL, let url = URL(string: urlString) else { return }
        let request = URLRequest(url: url)
        webView.load(request)
    }
    
    
    private func setupCloseButton() {
        let closeButton = UIButton(type: .system)
        closeButton.setTitle("Закрыть", for: .normal)
        closeButton.setTitleColor(.white, for: .normal)
        closeButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        closeButton.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        closeButton.layer.cornerRadius = 8
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        
        view.addSubview(closeButton)
        
        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            closeButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            closeButton.widthAnchor.constraint(equalToConstant: 80),
            closeButton.heightAnchor.constraint(equalToConstant: 36)
        ])
    }
    
    @objc private func closeButtonTapped() {
        dismiss(animated: true, completion: nil)
    }



    
    
    
    
    
    
    
    
    
    
    
    
    
    
    private func setupControlButtons() {
        
        func createControlButton(title: String, startAction: Selector, stopAction: Selector) -> UIButton {
            let button = UIButton(type: .system)
            button.setTitle(title, for: .normal)
            button.titleLabel?.font = .systemFont(ofSize: 28)
            button.backgroundColor = UIColor.black.withAlphaComponent(0.6)
            button.setTitleColor(.white, for: .normal)
            button.layer.cornerRadius = 30
            button.translatesAutoresizingMaskIntoConstraints = false

            button.addTarget(self, action: startAction, for: .touchDown)
            button.addTarget(self, action: stopAction, for: .touchUpInside)
            button.addTarget(self, action: stopAction, for: .touchUpOutside)
            button.addTarget(self, action: stopAction, for: .touchCancel)

            return button
        }


        
        let forwardButton = createControlButton(title: "⬆️", startAction: #selector(startMovingForward), stopAction: #selector(stopMovingForward))
        view.addSubview(forwardButton)
        NSLayoutConstraint.activate([
            forwardButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 60),
            forwardButton.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -40),
            forwardButton.widthAnchor.constraint(equalToConstant: 60),
            forwardButton.heightAnchor.constraint(equalToConstant: 60)
        ])

        
        let backwardButton = createControlButton(title: "⬇️", startAction: #selector(startMovingBackward), stopAction: #selector(stopMovingBackward))
        view.addSubview(backwardButton)
        NSLayoutConstraint.activate([
            backwardButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 60),
            backwardButton.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: 40),
            backwardButton.widthAnchor.constraint(equalToConstant: 60),
            backwardButton.heightAnchor.constraint(equalToConstant: 60)
        ])

     
        let leftButton = createControlButton(title: "⬅️", startAction: #selector(startTurningLeft), stopAction: #selector(stopTurningLeft))
        view.addSubview(leftButton)
        NSLayoutConstraint.activate([
            leftButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -60),
            leftButton.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -40),
            leftButton.widthAnchor.constraint(equalToConstant: 60),
            leftButton.heightAnchor.constraint(equalToConstant: 60)
        ])

    
        let rightButton = createControlButton(title: "➡️", startAction: #selector(startTurningRight), stopAction: #selector(stopTurningRight))
        view.addSubview(rightButton)
        NSLayoutConstraint.activate([
            rightButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -60),
            rightButton.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: 40),
            rightButton.widthAnchor.constraint(equalToConstant: 60),
            rightButton.heightAnchor.constraint(equalToConstant: 60)
        ])
    }

    @objc func startMovingForward() { commandSender?.moveForward(isPressed: true) }
    @objc func stopMovingForward() { commandSender?.moveForward(isPressed: false) }

    @objc func startMovingBackward() { commandSender?.moveBackward(isPressed: true) }
    @objc func stopMovingBackward() { commandSender?.moveBackward(isPressed: false) }

    @objc func startTurningLeft() { commandSender?.turnLeft(isPressed: true) }
    @objc func stopTurningLeft() { commandSender?.turnLeft(isPressed: false) }

    @objc func startTurningRight() { commandSender?.turnRight(isPressed: true) }
    @objc func stopTurningRight() { commandSender?.turnRight(isPressed: false) }

    @objc func stopMove() { commandSender?.stopTheMovement() }

    
    @objc private func close() {
        dismiss(animated: true)
    }
}


// Вызываем изменение угла колес, если оно требуется для этой логики
//                pad.onWheelAngleChanged = { [weak self] wheelAngle in
//                    guard let self = self else { return }
//                    print("Wheel angle: \(wheelAngle * 180 / .pi)°") // Показываем угол колеса в градусах
//                    self.directionOverlayLeft.directionAngle = wheelAngle
//                    self.directionOverlayRight.directionAngle = wheelAngle
//                }
//            }
