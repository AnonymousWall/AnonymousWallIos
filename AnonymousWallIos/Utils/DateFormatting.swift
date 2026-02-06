//
//  DateFormatting.swift
//  AnonymousWallIos
//
//  Utility for consistent date formatting across the app
//

import Foundation

struct DateFormatting {
    // Reusable date formatters to avoid expensive initialization
    private static let iso8601Formatter = ISO8601DateFormatter()
    private static let dateTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy HH:mm"
        return formatter
    }()
    
    /// Parse a date string that may include timezone and microseconds
    /// - Parameter dateString: Date string in various formats
    /// - Returns: Date object or nil if parsing fails
    private static func parseDate(_ dateString: String) -> Date? {
        // Try standard ISO8601 first
        if let date = iso8601Formatter.date(from: dateString) {
            return date
        }
        
        // Handle formats like: 2026-02-05T23:46:03.614917-08:00[America/Los_Angeles]
        // Remove the timezone name in brackets if present
        var cleanedString = dateString
        if let bracketIndex = dateString.firstIndex(of: "[") {
            cleanedString = String(dateString[..<bracketIndex])
        }
        
        // Truncate microseconds to milliseconds (DateFormatter only supports 3 digits)
        // Pattern: find .NNNNNN (more than 3 digits after decimal) and truncate to .NNN
        if let dotIndex = cleanedString.firstIndex(of: "."),
           let endIndex = cleanedString[dotIndex...].firstIndex(where: { !$0.isNumber && $0 != "." }) {
            let fractionalPart = cleanedString[cleanedString.index(after: dotIndex)..<endIndex]
            if fractionalPart.count > 3 {
                let truncated = String(fractionalPart.prefix(3))
                let rest = cleanedString[endIndex...]
                cleanedString = String(cleanedString[...dotIndex]) + truncated + rest
            }
        }
        
        // Try parsing with fractional seconds
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        
        // Try different formats with fractional seconds
        let formats = [
            "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ",     // Milliseconds with timezone
            "yyyy-MM-dd'T'HH:mm:ssZZZZZ",         // No fractional seconds with timezone
            "yyyy-MM-dd'T'HH:mm:ss.SSS",          // Milliseconds without timezone
            "yyyy-MM-dd'T'HH:mm:ss"               // No fractional seconds
        ]
        
        for format in formats {
            formatter.dateFormat = format
            if let date = formatter.date(from: cleanedString) {
                return date
            }
        }
        
        return nil
    }
    
    /// Format a date string to dd/MM/yyyy HH:mm format
    /// - Parameter dateString: ISO 8601 date string
    /// - Returns: Formatted date and time string
    static func formatDateTime(_ dateString: String) -> String {
        if let date = parseDate(dateString) {
            return dateTimeFormatter.string(from: date)
        }
        
        // Fallback if date parsing fails
        return dateString
    }
    
    /// Legacy function name for backwards compatibility
    /// - Parameter dateString: ISO 8601 date string
    /// - Returns: Formatted date and time string
    static func formatRelativeTime(_ dateString: String) -> String {
        return formatDateTime(dateString)
    }
}
