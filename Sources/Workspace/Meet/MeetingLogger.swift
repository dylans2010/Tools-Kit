/*
 * Summary: Unified logger for the Meet module.
 * Changes: Created os.Logger wrappers for Daily SDK and Crypto operations.
 */

import Foundation
import os

/// Unified logger for the Meet module.
public enum MeetingLogger {
    private static let subsystem = "com.app.meet"

    /// Logger for general meeting operations.
    public static let shared = Logger(subsystem: subsystem, category: "General")

    /// Logger for Daily.co SDK interactions.
    public static let daily = Logger(subsystem: subsystem, category: "DailySDK")

    /// Logger for encryption/decryption operations.
    public static let crypto = Logger(subsystem: subsystem, category: "Crypto")

    /// Logs a debug message with function name.
    public static func debug(_ message: String, category: Logger = shared, function: String = #function) {
        category.debug("[\(function)] \(message)")
    }

    /// Logs an info message with function name.
    public static func info(_ message: String, category: Logger = shared, function: String = #function) {
        category.info("[\(function)] \(message)")
    }

    /// Logs an error message with function name.
    public static func error(_ message: String, category: Logger = shared, function: String = #function) {
        category.error("[\(function)] \(message)")
    }
}
