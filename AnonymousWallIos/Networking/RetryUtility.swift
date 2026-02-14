//
//  RetryUtility.swift
//  AnonymousWallIos
//
//  Utility for retrying async operations with exponential backoff
//

import Foundation

/// Utility for executing async operations with retry and exponential backoff
actor RetryUtility {
    /// Execute an async operation with retry logic
    /// - Parameters:
    ///   - policy: The retry policy to use
    ///   - operation: The async operation to execute
    /// - Returns: The result of the operation
    /// - Throws: The last error if all retries are exhausted
    static func execute<T>(
        policy: RetryPolicy = .default,
        operation: @Sendable () async throws -> T
    ) async throws -> T {
        var lastError: Error?
        var attempt = 0
        
        // Initial attempt + retries
        let totalAttempts = 1 + policy.maxAttempts
        
        while attempt < totalAttempts {
            do {
                // Try to execute the operation
                let result = try await operation()
                return result
            } catch {
                lastError = error
                
                // Check if we've exhausted all attempts
                if attempt >= policy.maxAttempts {
                    throw error
                }
                
                // Check if the error is retriable
                guard policy.shouldRetry(error) else {
                    throw error
                }
                
                // Calculate delay for exponential backoff
                let delay = policy.delay(for: attempt)
                
                // Log retry attempt (optional, for debugging)
                if AppConfiguration.shared.enableLogging {
                    Logger.network.debug("Retrying after \(delay)s (attempt \(attempt + 1)/\(policy.maxAttempts))")
                }
                
                // Wait before retrying (respects cancellation)
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                
                attempt += 1
            }
        }
        
        // This should never be reached, but throw the last error as a safety net
        throw lastError ?? NetworkError.networkError(NSError(domain: "RetryUtility", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unknown retry error"]))
    }
}
