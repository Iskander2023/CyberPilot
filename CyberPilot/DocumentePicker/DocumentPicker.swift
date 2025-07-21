//
//  DocumentPicker.swift
//  CyberPilot
//
//  Created by Admin on 17/07/25.
//

import UniformTypeIdentifiers
import SwiftUI


struct DocumentPicker: UIViewControllerRepresentable {
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.item])
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let selectedFileURL = urls.first else { return }
            print("Файл выбран: \(selectedFileURL.lastPathComponent)")
            // Обработка выбранного файла
        }
    }
}
