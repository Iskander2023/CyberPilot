//
//  AllertManager.swift
//  CyberPilot
//
//  Created by Aleksandr Chumakov on 10/04/25.
//

import SwiftUI


class AlertManager: ObservableObject {
    @Published var isPresented = false
    var title: String = ""
    var message: String = ""

    func showAlert(title: String, message: String) {
        self.title = title
        self.message = message
        self.isPresented = true
    }
}


struct GlobalAlertModifier: ViewModifier {
    @EnvironmentObject var alertManager: AlertManager

    func body(content: Content) -> some View {
        content
            .alert(isPresented: $alertManager.isPresented) {
                Alert(
                    title: Text(alertManager.title),
                    message: Text(alertManager.message),
                    dismissButton: .default(Text("OK"))
                )
            }
    }
}

extension View {
    func globalAlert() -> some View {
        self.modifier(GlobalAlertModifier())
    }
}


