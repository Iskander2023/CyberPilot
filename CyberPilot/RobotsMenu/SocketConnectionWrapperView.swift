////
////  SocketConnectionWrapperView.swift
////  CyberPilot
////
////  Created by Admin on 24/07/25.
////
//
//import SwiftUI
//
//
//struct SocketConnectionWrapperView: View {
//    let robot: Robot
//    @EnvironmentObject var controller: SocketController
//    @State private var isConnecting = true
//    @State private var connectionFailed = false
//
//    var body: some View {
//        Group {
//            if isConnecting {
//                ProgressView("Подключение к роботу...")
//                    .onAppear {
//                        connectToRobot()
//                    }
//            } else if connectionFailed {
//                VStack(spacing: 12) {
//                    Text("Не удалось подключиться")
//                        .foregroundColor(.red)
//                    Button("Повторить") {
//                        isConnecting = true
//                        connectionFailed = false
////                        connectToRobot()
//                    }
//                }
//            } else {
//                SocketView()
//            }
//        }
//    }
//
////    private func connectToRobot() {
////        controller.setCurrentRobot(robot)
////        controller.connectionManager.connect { success in
////            DispatchQueue.main.async {
////                if success {
////                    isConnecting = false
////                } else {
////                    connectionFailed = true
////                }
////            }
////        }
//   /* */}
//}
