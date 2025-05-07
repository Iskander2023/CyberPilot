//
//  RobotSelectionView.swift
//  CyberPilot
//
//  Created by Admin on 6/05/25.
//

import SwiftUI


struct RobotSelectionView: View {
    let robots: [[String: Any]]
    var onSelect: (_ robot: [String: Any]) -> Void

    var body: some View {
        NavigationView {
            List {
                ForEach(robots.indices, id: \.self) { index in
                    let robot = robots[index]
                    Button(action: {
                        onSelect(robot)
                    }) {
                        Text(robot["robotId"] as? String ?? "Робот \(index + 1)")
                    }
                }
            }
            .navigationTitle("Выбор робота")
        }
    }
}
