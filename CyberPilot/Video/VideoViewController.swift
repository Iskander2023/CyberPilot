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


    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupWebView()
        loadVideoStream()
        setupCloseButton()
        setupControlButtons()
        guard commandSender != nil else {
                print("⚠️ CommandSender не был передан!")
                return
            }
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
        closeButton.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        closeButton.layer.cornerRadius = 8
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.addTarget(self, action: #selector(close), for: .touchUpInside)
        view.addSubview(closeButton)

        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -15),
            closeButton.widthAnchor.constraint(equalToConstant: 100),
            closeButton.heightAnchor.constraint(equalToConstant: 40)
        ])
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


        // Вперёд
        let forwardButton = createControlButton(title: "⬆️", startAction: #selector(startMovingForward), stopAction: #selector(stopMovingForward))
        view.addSubview(forwardButton)
        NSLayoutConstraint.activate([
            forwardButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 60),
            forwardButton.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -40),
            forwardButton.widthAnchor.constraint(equalToConstant: 60),
            forwardButton.heightAnchor.constraint(equalToConstant: 60)
        ])

        // Назад
        let backwardButton = createControlButton(title: "⬇️", startAction: #selector(startMovingBackward), stopAction: #selector(stopMovingBackward))
        view.addSubview(backwardButton)
        NSLayoutConstraint.activate([
            backwardButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 60),
            backwardButton.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: 40),
            backwardButton.widthAnchor.constraint(equalToConstant: 60),
            backwardButton.heightAnchor.constraint(equalToConstant: 60)
        ])

        // Влево
        let leftButton = createControlButton(title: "⬅️", startAction: #selector(startTurningLeft), stopAction: #selector(stopTurningLeft))
        view.addSubview(leftButton)
        NSLayoutConstraint.activate([
            leftButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -60),
            leftButton.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -40),
            leftButton.widthAnchor.constraint(equalToConstant: 60),
            leftButton.heightAnchor.constraint(equalToConstant: 60)
        ])

        // Вправо
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

