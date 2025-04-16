//
//  UserMessage.swift
//  CyberPilot
//
//  Created by Admin on 9/04/25.
//
import UIKit


class UserMessageUIKit {
    
    static func showAlert(on viewController: UIViewController, title: String, message: String) {
        DispatchQueue.main.async {
            if let presented = viewController.presentedViewController, presented is UIAlertController {
                presented.dismiss(animated: false) {
                    self.presentAlert(on: viewController, title: title, message: message)
                }
            } else {
                self.presentAlert(on: viewController, title: title, message: message)
            }
        }
    }

    private static func presentAlert(on viewController: UIViewController, title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        viewController.present(alert, animated: true, completion: nil)
    }
}

