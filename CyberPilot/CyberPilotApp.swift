//
//  CyberPilotApp.swift
//  CyberPilot
//
//  Created by Admin on 5/04/25.
//

import SwiftUI

@main
struct CyberPilotApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
