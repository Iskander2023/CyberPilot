//
//  RobotSelectionView.swift
//  CyberPilot
//
//  Created by Admin on 6/05/25.
//

import SwiftUI


struct RobotSelectionView: View {
    @ObservedObject var viewModel: RobotListViewModel
    @EnvironmentObject var controller: SocketController

    var body: some View {
        NavigationView {
            List(viewModel.robots) { robot in
                NavigationLink(
                    destination: SocketView()
                        .environmentObject(controller)
                        .onAppear {
                            controller.setCurrentRobot(robot)
                        }
                ) {
                    HStack {
                        Text(robot.robot_id)
                        Spacer()
                        Text(robot.status.rawValue.capitalized)
                            .foregroundColor(robot.status == .online ? .green : .gray)
                        Spacer()
                        Text(robot.last_updated.formatted(date: .numeric, time: .shortened))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Мои роботы")
            .onAppear {
                viewModel.fetchRobots()
            }
        }
    }
}



