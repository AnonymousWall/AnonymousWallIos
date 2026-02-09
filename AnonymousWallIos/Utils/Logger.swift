//
//  Logger.swift
//  AnonymousWallIos
//
//  Centralized logging infrastructure with support for Debug, Info, Warning, and Error levels
//

import Foundation
import os.log

/// Log levels for structured logging
enum LogLevel: String {
    case debug = "🔍 DEBUG"
    case info = "ℹ️ INFO"
    case warning = "⚠️ WARNING"
    case error = "❌ ERROR"
    
    var osLogType: OSLogType {
        switch self {
        case .debug:
            return .debug
        case .info:
            return .info
        case .warning:
            return .default
        case .error:
            return .error
        }
    }
}

/// Centralized logging system for the app
struct Logger {
    // MARK: - Properties
    
    private let subsystem: String
    private let category: String
    private let osLog: OSLog
    
    // MARK: - Initialization
    
    /// Initialize a logger with a specific subsystem and category
    /// - Parameters:
    ///   - subsystem: The subsystem identifier (defaults to bundle identifier)
    ///   - category: The category for this logger (e.g., "Networking", "Authentication", "UI")
    init(subsystem: String = Bundle.main.bundleIdentifier ?? "com.anonymouswall.ios",
         category: String = "General") {
        self.subsystem = subsystem
        self.category = category
        self.osLog = OSLog(subsystem: subsystem, category: category)
    }
    
    // MARK: - Logging Methods
    
    /// Log a debug message
    /// - Parameters:
    ///   - message: The message to log
    ///   - file: The file where the log was called (automatically provided)
    ///   - function: The function where the log was called (automatically provided)
    ///   - line: The line number where the log was called (automatically provided)
    func debug(_ message: String,
               file: String = #file,
               function: String = #function,
               line: Int = #line) {
        log(level: .debug, message: message, file: file, function: function, line: line)
    }
    
    /// Log an info message
    /// - Parameters:
    ///   - message: The message to log
    ///   - file: The file where the log was called (automatically provided)
    ///   - function: The function where the log was called (automatically provided)
    ///   - line: The line number where the log was called (automatically provided)
    func info(_ message: String,
              file: String = #file,
              function: String = #function,
              line: Int = #line) {
        log(level: .info, message: message, file: file, function: function, line: line)
    }
    
    /// Log a warning message
    /// - Parameters:
    ///   - message: The message to log
    ///   - file: The file where the log was called (automatically provided)
    ///   - function: The function where the log was called (automatically provided)
    ///   - line: The line number where the log was called (automatically provided)
    func warning(_ message: String,
                 file: String = #file,
                 function: String = #function,
                 line: Int = #line) {
        log(level: .warning, message: message, file: file, function: function, line: line)
    }
    
    /// Log an error message
    /// - Parameters:
    ///   - message: The message to log
    ///   - file: The file where the log was called (automatically provided)
    ///   - function: The function where the log was called (automatically provided)
    ///   - line: The line number where the log was called (automatically provided)
    func error(_ message: String,
               file: String = #file,
               function: String = #function,
               line: Int = #line) {
        log(level: .error, message: message, file: file, function: function, line: line)
    }
    
    // MARK: - Private Methods
    
    private func log(level: LogLevel,
                     message: String,
                     file: String,
                     function: String,
                     line: Int) {
        let config = AppConfiguration.shared
        
        // Only log if logging is enabled for current environment
        guard config.enableLogging else { return }
        
        let fileName = (file as NSString).lastPathComponent
        let formattedMessage = "[\(category)] \(level.rawValue) [\(fileName):\(line)] \(function) - \(message)"
        
        // Use os.log for structured logging (visible in Console.app and Xcode)
        os_log("%{public}@", log: osLog, type: level.osLogType, formattedMessage)
        
        // In development, also print to console for convenience
        if config.environment == .development {
            print(formattedMessage)
        }
    }
}

// MARK: - Convenience Loggers

extension Logger {
    /// Shared logger for networking operations
    static let network = Logger(category: "Networking")
    
    /// Shared logger for authentication operations
    static let auth = Logger(category: "Authentication")
    
    /// Shared logger for UI operations
    static let ui = Logger(category: "UI")
    
    /// Shared logger for general/uncategorized operations
    static let general = Logger(category: "General")
    
    /// Shared logger for data operations (storage, caching, etc.)
    static let data = Logger(category: "Data")
}
