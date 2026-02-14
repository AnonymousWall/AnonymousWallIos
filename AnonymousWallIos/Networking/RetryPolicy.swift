//
//  RetryPolicy.swift
//  AnonymousWallIos
//
//  Configuration for retry behavior with exponential backoff
//

import Foundation

/// Configuration for retry behavior
struct RetryPolicy {
    /// Maximum number of retry attempts (excluding the initial request)
    let maxAttempts: Int
    
    /// Base delay in seconds for exponential backoff
    let baseDelay: TimeInterval
    
    /// Maximum delay in seconds to cap exponential backoff
    let maxDelay: TimeInterval
    
    /// Default retry policy with 3 attempts and exponential backoff
    static let `default` = RetryPolicy(
        maxAttempts: 3,
        baseDelay: 0.5,
        maxDelay: 5.0
    )
    
    /// No retry policy (immediate failure)
    static let none = RetryPolicy(
        maxAttempts: 0,
        baseDelay: 0,
        maxDelay: 0
    )
    
    init(maxAttempts: Int, baseDelay: TimeInterval, maxDelay: TimeInterval) {
        self.maxAttempts = max(0, maxAttempts)
        self.baseDelay = max(0, baseDelay)
        self.maxDelay = max(baseDelay, maxDelay)
    }
    
    /// Calculate delay for a specific retry attempt using exponential backoff
    /// - Parameter attempt: The attempt number (0-based)
    /// - Returns: Delay in seconds before the next retry
    func delay(for attempt: Int) -> TimeInterval {
        let exponentialDelay = baseDelay * pow(2.0, Double(attempt))
        return min(exponentialDelay, maxDelay)
    }
    
    /// Determine if an error should be retried
    /// - Parameter error: The error to evaluate
    /// - Returns: true if the error is retriable, false otherwise
    func shouldRetry(_ error: Error) -> Bool {
        // Retry network timeouts and connection errors
        if let urlError = error as? URLError {
            switch urlError.code {
            case .timedOut, .networkConnectionLost, .notConnectedToInternet:
                return true
            case .cancelled:
                return false
            default:
                return false
            }
        }
        
        // Retry NetworkError timeouts and connection issues
        if let networkError = error as? NetworkError {
            switch networkError {
            case .timeout, .noConnection:
                return true
            case .serverError5xx:
                // Retry server errors (5xx responses)
                return true
            case .cancelled:
                return false
            default:
                // Don't retry client errors (4xx) or other errors
                return false
            }
        }
        
        return false
    }
}
