//
//  Logger.swift
//  Promptist
//
//  Centralized logging service for consistent error handling and debugging.
//

import Foundation
import os.log

/// Centralized logging service providing consistent logging across the app.
/// Uses Apple's unified logging system (os.log) for better performance and integration.
enum AppLogger {
    // MARK: - Subsystems

    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.promptist.app"

    // MARK: - Categories

    private static let persistence = Logger(subsystem: subsystem, category: "Persistence")
    private static let shortcuts = Logger(subsystem: subsystem, category: "Shortcuts")
    private static let execution = Logger(subsystem: subsystem, category: "Execution")
    private static let accessibility = Logger(subsystem: subsystem, category: "Accessibility")
    private static let general = Logger(subsystem: subsystem, category: "General")

    // MARK: - Persistence Logging

    /// Log persistence-related events (save, load, migration)
    static func logPersistence(
        _ message: String,
        level: LogLevel = .info,
        error: Error? = nil
    ) {
        log(to: persistence, message: message, level: level, error: error)
    }

    // MARK: - Shortcut Logging

    /// Log shortcut-related events (registration, triggering, conflicts)
    static func logShortcut(
        _ message: String,
        level: LogLevel = .info,
        error: Error? = nil
    ) {
        log(to: shortcuts, message: message, level: level, error: error)
    }

    // MARK: - Execution Logging

    /// Log prompt execution events (copy, variable resolution)
    static func logExecution(
        _ message: String,
        level: LogLevel = .info,
        error: Error? = nil
    ) {
        log(to: execution, message: message, level: level, error: error)
    }

    // MARK: - Accessibility Logging

    /// Log accessibility permission events
    static func logAccessibility(
        _ message: String,
        level: LogLevel = .info,
        error: Error? = nil
    ) {
        log(to: accessibility, message: message, level: level, error: error)
    }

    // MARK: - General Logging

    /// Log general app events
    static func log(
        _ message: String,
        level: LogLevel = .info,
        error: Error? = nil
    ) {
        log(to: general, message: message, level: level, error: error)
    }

    // MARK: - Private Implementation

    private static func log(
        to logger: Logger,
        message: String,
        level: LogLevel,
        error: Error?
    ) {
        let fullMessage: String
        if let error = error {
            fullMessage = "\(message) - Error: \(error.localizedDescription)"
        } else {
            fullMessage = message
        }

        switch level {
        case .debug:
            logger.debug("\(fullMessage)")
        case .info:
            logger.info("\(fullMessage)")
        case .warning:
            logger.warning("\(fullMessage)")
        case .error:
            logger.error("\(fullMessage)")
        case .fault:
            logger.fault("\(fullMessage)")
        }
    }
}

// MARK: - Log Level

extension AppLogger {
    enum LogLevel {
        case debug
        case info
        case warning
        case error
        case fault
    }
}
