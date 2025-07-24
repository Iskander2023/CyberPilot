//
//  CustomTextField.swift
//  CyberPilot
//
//  Created by Admin on 17/07/25.
//

import SwiftUI


struct CustomTextField: UIViewRepresentable {
    @Binding var text: String
    var placeholder: String

    
    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField()
        textField.placeholder = placeholder
        textField.delegate = context.coordinator

        
        textField.inputAssistantItem.leadingBarButtonGroups = []
        textField.inputAssistantItem.trailingBarButtonGroups = []

        textField.font = UIFont.preferredFont(forTextStyle: .title2)
        return textField
    }

    
    func updateUIView(_ uiView: UITextField, context: Context) {
        uiView.text = text
    }

    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    
    class Coordinator: NSObject, UITextFieldDelegate {
        var parent: CustomTextField

        init(_ parent: CustomTextField) {
            self.parent = parent
        }

        func textFieldDidChangeSelection(_ textField: UITextField) {
            parent.text = textField.text ?? ""
        }
    }
}

