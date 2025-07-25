//
//  TokenProtocol.swift
//  CyberPilot
//
//  Created by Admin on 15/05/25.
//

import Foundation
import Combine

let logger = CustomLogger(logLevel: .info, includeMetadata: false)

protocol TokenUpdatable: AnyObject {
    var token: String? { get set }
    var cancellables: Set<AnyCancellable> { get set }

    func updateToken(_ newToken: String?)
    func setupTokenBinding(from robotManager: AuthService)
}

extension TokenUpdatable {
    func setupTokenBinding(from robotManager: AuthService) {
        robotManager.$accessToken
            .sink { [weak self] newToken in
                self?.token = newToken
                self?.updateToken(newToken)  // ВАЖНО: теперь вызывается updateToken
                logger.debug("Token updated via protocol: \(newToken ?? "nil")")
            }
            .store(in: &cancellables)
    }
}

