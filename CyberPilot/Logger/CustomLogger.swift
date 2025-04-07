//
//  LoggerFormatter.swift
//  Robot_Controller
//
//  Created by Aleksandr Chumakov on 13/03/25.
//

import Foundation


protocol Logger {
    func debug(_ message: String, file: String, line: Int, function: String)
    func info(_ message: String, file: String, line: Int, function: String)
    func warn(_ message: String, file: String, line: Int, function: String)
    func error(_ message: String, file: String, line: Int, function: String)
}

class CustomLogger: Logger {
    private let logLevel: LogLevel
    private let includeMetadata: Bool

    init(logLevel: LogLevel = .info, includeMetadata: Bool = false) {
        self.logLevel = logLevel
        self.includeMetadata = includeMetadata
    }

    // Реализация методов протокола Logger
    func debug(_ message: String, file: String = #file, line: Int = #line, function: String = #function) {
        log(message, level: .debug, file: file, line: line, function: function)
    }

    func info(_ message: String, file: String = #file, line: Int = #line, function: String = #function) {
        log(message, level: .info, file: file, line: line, function: function)
    }

    func warn(_ message: String, file: String = #file, line: Int = #line, function: String = #function) {
        log(message, level: .warn, file: file, line: line, function: function)
    }

    func error(_ message: String, file: String = #file, line: Int = #line, function: String = #function) {
        log(message, level: .error, file: file, line: line, function: function)
    }

    // Общий метод для логирования
    private func log(_ message: String, level: LogLevel, file: String, line: Int, function: String) {
        guard level.rawValue >= logLevel.rawValue else { return }

        // Форматирование даты с миллисекундами
        let date = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        let dateString = formatter.string(from: date)

        if includeMetadata {
            print("[\(dateString)] [\(level)] [\((file as NSString).lastPathComponent):\(line)] \(function) - \(message)")
        } else {
            print("[\(dateString)] [\(level)] \(message)")
        }
    }
}

enum LogLevel: Int {
    case debug = 1
    case info = 2
    case warn = 3
    case error = 4
}
