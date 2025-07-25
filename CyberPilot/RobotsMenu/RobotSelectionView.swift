//
//  RobotSelectionView.swift
//  CyberPilot
//
//  Created by Aleksandr Chumakov on 6/05/25.
//

import SwiftUI



/// вью выбора доступных пользователю роботов
/// загружается сразу после успешной авторизации/регистрации
/// в момент нажатия на кнопку выбраного робота, назначает выбраного робота (controller.setCurrentRobot(robot)). также формируется url для подключения к сокету
/// после этого выполняется подключение к сокету  если подключение успешно, переходит в меню управления роботом
/// при выходе в эту вью выполняется отключение сокета
/// если робот пользователю не назначен, возможности перейти дальше в меню нет
///
///


struct RobotSelectionView: View {
    @EnvironmentObject var viewModel: RobotListViewModel
    @EnvironmentObject var controller: SocketController

    @State private var selectedRobot: Robot?
    @State private var isNavigating = false
    @State private var isConnecting = false
    @State private var connectionFailed = false

    var body: some View {
        NavigationStack {
            VStack {
                if isConnecting {
                    ProgressView("Подключение к роботу…")
                        .padding()
                }

                if connectionFailed {
                    Text("❌ Не удалось подключиться")
                        .foregroundColor(.red)
                        .padding(.bottom, 8)
                }

                List(viewModel.robots) { robot in
                    Button(action: {
                        guard robot.status == .online else { return }
                        selectedRobot = robot
                        isConnecting = true
                        connectionFailed = false

                        controller.setCurrentRobot(robot)
                        controller.connectionManager.connect { success in
                            DispatchQueue.main.async {
                                isConnecting = false // Сбрасываем флаг загрузки в любом случае
                                if success {
                                    isNavigating = true // Переход произойдет автоматически благодаря navigationDestination
                                } else {
                                    connectionFailed = true
                                }
                            }
                        }
                    }) {
                        HStack {
                            Text("Robot id: \(String(robot.robot_id.prefix(4)))…")
                            Spacer()
                            Text("Status: \(robot.status.rawValue)")
                                .foregroundColor(robot.status == .online ? .green : .red)
                        }
                        .frame(height: 50)
                        .padding(2)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(
                                    robot.status == .online ? Color.green : Color.red,
                                    lineWidth: 1.5
                                )
                        )
                    }
                    .disabled(robot.status != .online)
                    .opacity(robot.status == .online ? 1.0 : 0.4)
                }

                .navigationDestination(isPresented: $isNavigating) {
                    SocketView()
                        .onDisappear {
                            controller.connectionManager.disconnect()
                            viewModel.fetchRobots()
                        }
                }
            }
            .navigationTitle(viewModel.robots.isEmpty ? "Нет роботов" : "Список доступных устройств ▶️")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                viewModel.fetchRobots()
            }
        }
    }
}
