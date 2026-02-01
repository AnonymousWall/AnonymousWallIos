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
    private static let mediumDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
    
    /// Format a date string to a relative time string (e.g., "5m ago", "2h ago")
    /// - Parameter dateString: ISO 8601 date string
    /// - Returns: Formatted relative time string
    static func formatRelativeTime(_ dateString: String) -> String {
        if let date = iso8601Formatter.date(from: dateString) {
            let now = Date()
            let timeInterval = now.timeIntervalSince(date)
            
            // Handle future dates (clock skew or incorrect timestamps)
            if timeInterval < 0 {
                return "Just now"
            }
            // Less than a minute
            else if timeInterval < 60 {
                return "Just now"
            }
            // Less than an hour
            else if timeInterval < 3600 {
                let minutes = Int(timeInterval / 60)
                return "\(minutes)m ago"
            }
            // Less than a day
            else if timeInterval < 86400 {
                let hours = Int(timeInterval / 3600)
                return "\(hours)h ago"
            }
            // Less than a week
            else if timeInterval < 604800 {
                let days = Int(timeInterval / 86400)
                return "\(days)d ago"
            }
            // More than a week
            else {
                return mediumDateFormatter.string(from: date)
            }
        }
        
        // Fallback if date parsing fails
        return dateString
    }
}
