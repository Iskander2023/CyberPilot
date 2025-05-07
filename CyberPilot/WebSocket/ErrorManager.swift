//
//  ErrorManager.swift
//  CyberPilot
//
//  Created by Aleksandr Chumakov on 7/05/25.
//
import SwiftUI


final class ErrorManager: ObservableObject {
    @Published var showError = false
    @Published var errorMessage = ""
    
    func show(_ message: String) {
        errorMessage = message
        showError = true
    }
}
