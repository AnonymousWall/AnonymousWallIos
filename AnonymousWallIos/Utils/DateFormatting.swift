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
    
    /// Format a date string to dd/MM/yyyy HH:mm format
    /// - Parameter dateString: ISO 8601 date string
    /// - Returns: Formatted date and time string
    static func formatDateTime(_ dateString: String) -> String {
        if let date = iso8601Formatter.date(from: dateString) {
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
