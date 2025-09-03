//
//  Logger.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 15/08/25.
//

import Foundation

enum LogCategory: String {
    case authentication = "AUTH"
    case examination = "EXAM"
    case network = "NET"
    case general = "APP"
    case patient = "PATIENT"
    case user = "USER"
    case taskAssignment = "TASK"
    case videoRecord = "VIDEO"
    case navigation = "NAV"
}

enum LogLevel: String {
    case debug = "🔍"
    case info = "ℹ️"
    case warning = "⚠️"
    case error = "🚨"
}

struct Logger {
    static func debug(_ message: String, category: LogCategory = .general) {
        log(message, level: .debug, category: category)
    }
    
    static func info(_ message: String, category: LogCategory = .general) {
        log(message, level: .info, category: category)
    }
    
    static func warning(_ message: String, category: LogCategory = .general) {
        log(message, level: .warning, category: category)
    }
    
    static func error(_ message: String, category: LogCategory = .general) {
        log(message, level: .error, category: category)
    }
    
    private static func log(_ message: String, level: LogLevel, category: LogCategory) {
        let timestamp = DateFormatter.logFormatter.string(from: Date())
        print("\(level.rawValue) [\(category.rawValue)] \(timestamp): \(message)")
    }
}

private extension DateFormatter {
    static let logFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter
    }()
}
