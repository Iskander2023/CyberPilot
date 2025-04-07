//
//  SSHConnectorApp.swift
//  SSHConnector
//
//  Created by Aleksandr Chumakov on 18.03.2025.
//

import SwiftUI


struct SocketView: UIViewControllerRepresentable {
    @ObservedObject var stateManager: RobotManager

    func makeUIViewController(context: Context) -> SocketController {
        return SocketController(stateManager: stateManager)
    }

    func updateUIViewController(_ uiViewController: SocketController, context: Context) {
    }
}
