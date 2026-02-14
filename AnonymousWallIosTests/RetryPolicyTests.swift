//
//  RetryPolicyTests.swift
//  AnonymousWallIosTests
//
//  Tests for RetryPolicy configuration and behavior
//

import Testing
@testable import AnonymousWallIos
import Foundation

struct RetryPolicyTests {
    
    // MARK: - Configuration Tests
    
    @Test func testDefaultPolicy() {
        let policy = RetryPolicy.default
        
        #expect(policy.maxAttempts == 3)
        #expect(policy.baseDelay == 0.5)
        #expect(policy.maxDelay == 5.0)
    }
    
    @Test func testNonePolicy() {
        let policy = RetryPolicy.none
        
        #expect(policy.maxAttempts == 0)
        #expect(policy.baseDelay == 0)
        #expect(policy.maxDelay == 0)
    }
    
    @Test func testCustomPolicy() {
        let policy = RetryPolicy(maxAttempts: 5, baseDelay: 1.0, maxDelay: 10.0)
        
        #expect(policy.maxAttempts == 5)
        #expect(policy.baseDelay == 1.0)
        #expect(policy.maxDelay == 10.0)
    }
    
    @Test func testNegativeAttemptsClampedToZero() {
        let policy = RetryPolicy(maxAttempts: -5, baseDelay: 1.0, maxDelay: 10.0)
        
        #expect(policy.maxAttempts == 0)
    }
    
    @Test func testNegativeDelayClampedToZero() {
        let policy = RetryPolicy(maxAttempts: 3, baseDelay: -1.0, maxDelay: 10.0)
        
        #expect(policy.baseDelay == 0)
    }
    
    // MARK: - Exponential Backoff Tests
    
    @Test func testExponentialBackoff() {
        let policy = RetryPolicy(maxAttempts: 5, baseDelay: 1.0, maxDelay: 100.0)
        
        // Test exponential growth: delay = baseDelay * 2^attempt
        #expect(policy.delay(for: 0) == 1.0)   // 1.0 * 2^0 = 1.0
        #expect(policy.delay(for: 1) == 2.0)   // 1.0 * 2^1 = 2.0
        #expect(policy.delay(for: 2) == 4.0)   // 1.0 * 2^2 = 4.0
        #expect(policy.delay(for: 3) == 8.0)   // 1.0 * 2^3 = 8.0
        #expect(policy.delay(for: 4) == 16.0)  // 1.0 * 2^4 = 16.0
    }
    
    @Test func testMaxDelayCap() {
        let policy = RetryPolicy(maxAttempts: 5, baseDelay: 1.0, maxDelay: 5.0)
        
        // Delays should be capped at maxDelay
        #expect(policy.delay(for: 0) == 1.0)
        #expect(policy.delay(for: 1) == 2.0)
        #expect(policy.delay(for: 2) == 4.0)
        #expect(policy.delay(for: 3) == 5.0)  // Capped at maxDelay
        #expect(policy.delay(for: 4) == 5.0)  // Capped at maxDelay
        #expect(policy.delay(for: 5) == 5.0)  // Capped at maxDelay
    }
    
    @Test func testSmallBaseDelay() {
        let policy = RetryPolicy(maxAttempts: 3, baseDelay: 0.1, maxDelay: 10.0)
        
        #expect(policy.delay(for: 0) == 0.1)
        #expect(policy.delay(for: 1) == 0.2)
        #expect(policy.delay(for: 2) == 0.4)
    }
    
    // MARK: - Retry Decision Tests (Network Errors)
    
    @Test func testShouldRetryTimeout() {
        let policy = RetryPolicy.default
        let error = URLError(.timedOut)
        
        #expect(policy.shouldRetry(error) == true)
    }
    
    @Test func testShouldRetryNetworkConnectionLost() {
        let policy = RetryPolicy.default
        let error = URLError(.networkConnectionLost)
        
        #expect(policy.shouldRetry(error) == true)
    }
    
    @Test func testShouldRetryNoConnection() {
        let policy = RetryPolicy.default
        let error = URLError(.notConnectedToInternet)
        
        #expect(policy.shouldRetry(error) == true)
    }
    
    @Test func testShouldNotRetryCancelled() {
        let policy = RetryPolicy.default
        let error = URLError(.cancelled)
        
        #expect(policy.shouldRetry(error) == false)
    }
    
    @Test func testShouldNotRetryBadURL() {
        let policy = RetryPolicy.default
        let error = URLError(.badURL)
        
        #expect(policy.shouldRetry(error) == false)
    }
    
    // MARK: - Retry Decision Tests (NetworkError)
    
    @Test func testShouldRetryNetworkErrorTimeout() {
        let policy = RetryPolicy.default
        let error = NetworkError.timeout
        
        #expect(policy.shouldRetry(error) == true)
    }
    
    @Test func testShouldRetryNetworkErrorNoConnection() {
        let policy = RetryPolicy.default
        let error = NetworkError.noConnection
        
        #expect(policy.shouldRetry(error) == true)
    }
    
    @Test func testShouldRetryServerError5xx() {
        let policy = RetryPolicy.default
        let error = NetworkError.serverError("Server error: 500")
        
        #expect(policy.shouldRetry(error) == true)
    }
    
    @Test func testShouldRetryServerError503() {
        let policy = RetryPolicy.default
        let error = NetworkError.serverError("Server error: 503")
        
        #expect(policy.shouldRetry(error) == true)
    }
    
    @Test func testShouldNotRetryNetworkErrorCancelled() {
        let policy = RetryPolicy.default
        let error = NetworkError.cancelled
        
        #expect(policy.shouldRetry(error) == false)
    }
    
    @Test func testShouldNotRetryUnauthorized() {
        let policy = RetryPolicy.default
        let error = NetworkError.unauthorized
        
        #expect(policy.shouldRetry(error) == false)
    }
    
    @Test func testShouldNotRetryForbidden() {
        let policy = RetryPolicy.default
        let error = NetworkError.forbidden
        
        #expect(policy.shouldRetry(error) == false)
    }
    
    @Test func testShouldNotRetryNotFound() {
        let policy = RetryPolicy.default
        let error = NetworkError.notFound
        
        #expect(policy.shouldRetry(error) == false)
    }
    
    @Test func testShouldNotRetryInvalidURL() {
        let policy = RetryPolicy.default
        let error = NetworkError.invalidURL
        
        #expect(policy.shouldRetry(error) == false)
    }
    
    @Test func testShouldNotRetryDecodingError() {
        let policy = RetryPolicy.default
        let decodingError = NSError(domain: "DecodingError", code: -1, userInfo: nil)
        let error = NetworkError.decodingError(decodingError)
        
        #expect(policy.shouldRetry(error) == false)
    }
    
    @Test func testShouldNotRetryGenericServerError() {
        let policy = RetryPolicy.default
        let error = NetworkError.serverError("Something went wrong")
        
        // Only server errors with "Server error:" prefix should be retried
        #expect(policy.shouldRetry(error) == false)
    }
}
