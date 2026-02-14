//
//  NetworkingEdgeCasesTests.swift
//  AnonymousWallIosTests
//
//  Comprehensive tests for networking edge cases, error mapping, and retry logic
//

import Testing
@testable import AnonymousWallIos
import Foundation

struct NetworkingEdgeCasesTests {
    
    // MARK: - Error Mapping Tests
    
    @Test func testHTTPStatusCode401MapsToUnauthorized() {
        let error = NetworkError.unauthorized
        
        #expect(error.errorDescription == "Unauthorized - please login again")
    }
    
    @Test func testHTTPStatusCode403MapsToForbidden() {
        let error = NetworkError.forbidden
        
        #expect(error.errorDescription == "Access forbidden")
    }
    
    @Test func testHTTPStatusCode404MapsToNotFound() {
        let error = NetworkError.notFound
        
        #expect(error.errorDescription == "Resource not found")
    }
    
    @Test func testHTTPStatusCode5xxMapsToServerError() {
        let error = NetworkError.serverError5xx("Internal Server Error", statusCode: 500)
        
        #expect(error.errorDescription == "Internal Server Error")
    }
    
    @Test func testTimeoutErrorMapping() {
        let error = NetworkError.timeout
        
        #expect(error.errorDescription == "Request timeout")
    }
    
    @Test func testNoConnectionErrorMapping() {
        let error = NetworkError.noConnection
        
        #expect(error.errorDescription == "No internet connection")
    }
    
    @Test func testCancelledErrorMapping() {
        let error = NetworkError.cancelled
        
        #expect(error.errorDescription == "Request cancelled")
    }
    
    @Test func testInvalidURLErrorMapping() {
        let error = NetworkError.invalidURL
        
        #expect(error.errorDescription == "Invalid URL")
    }
    
    @Test func testDecodingErrorMapping() {
        let underlyingError = NSError(domain: "DecodingError", code: -1, userInfo: nil)
        let error = NetworkError.decodingError(underlyingError)
        
        #expect(error.errorDescription?.contains("Failed to decode response") == true)
    }
    
    // MARK: - Retry Logic with Cancellation Tests
    
    @Test func testRetryCancellationRespected() async throws {
        let policy = RetryPolicy(maxAttempts: 10, baseDelay: 0.5, maxDelay: 5.0)
        var attemptCount = 0
        
        let task = Task {
            try await RetryUtility.execute(policy: policy) {
                attemptCount += 1
                throw NetworkError.timeout
            }
        }
        
        // Cancel after short delay
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        task.cancel()
        
        do {
            _ = try await task.value
            Issue.record("Expected cancellation error")
        } catch {
            // Should be cancelled before exhausting all retries
            #expect(attemptCount <= 3)
        }
    }
    
    @Test func testRetryWithImmediateCancellation() async throws {
        let policy = RetryPolicy(maxAttempts: 5, baseDelay: 0.1, maxDelay: 1.0)
        var attemptCount = 0
        
        let task = Task {
            try await RetryUtility.execute(policy: policy) {
                attemptCount += 1
                throw NetworkError.noConnection
            }
        }
        
        // Cancel immediately
        task.cancel()
        
        do {
            _ = try await task.value
        } catch {
            // May complete first attempt before cancellation
            #expect(attemptCount <= 2)
        }
    }
    
    @Test func testCancellationDuringRetryDelay() async throws {
        let policy = RetryPolicy(maxAttempts: 5, baseDelay: 1.0, maxDelay: 5.0)
        var attemptCount = 0
        
        let task = Task {
            try await RetryUtility.execute(policy: policy) {
                attemptCount += 1
                throw NetworkError.serverError5xx("Service Unavailable", statusCode: 503)
            }
        }
        
        // Cancel during the retry delay
        try await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
        task.cancel()
        
        do {
            _ = try await task.value
            Issue.record("Expected error")
        } catch {
            // Should be cancelled during retry delay
            #expect(attemptCount <= 2)
        }
    }
    
    // MARK: - Retry with Different Error Types Tests
    
    @Test func testRetryTimeoutErrors() async throws {
        var attemptCount = 0
        let policy = RetryPolicy(maxAttempts: 3, baseDelay: 0.01, maxDelay: 0.1)
        
        do {
            _ = try await RetryUtility.execute(policy: policy) {
                attemptCount += 1
                throw NetworkError.timeout
            }
            Issue.record("Expected error")
        } catch {
            // Should retry 3 times (1 initial + 3 retries)
            #expect(attemptCount == 4)
            #expect(error as? NetworkError == NetworkError.timeout)
        }
    }
    
    @Test func testRetryConnectionErrors() async throws {
        var attemptCount = 0
        let policy = RetryPolicy(maxAttempts: 2, baseDelay: 0.01, maxDelay: 0.1)
        
        do {
            _ = try await RetryUtility.execute(policy: policy) {
                attemptCount += 1
                throw NetworkError.noConnection
            }
            Issue.record("Expected error")
        } catch {
            // Should retry (1 initial + 2 retries)
            #expect(attemptCount == 3)
        }
    }
    
    @Test func testRetryServerErrors() async throws {
        var attemptCount = 0
        let policy = RetryPolicy(maxAttempts: 2, baseDelay: 0.01, maxDelay: 0.1)
        
        do {
            _ = try await RetryUtility.execute(policy: policy) {
                attemptCount += 1
                throw NetworkError.serverError5xx("Internal Server Error", statusCode: 500)
            }
            Issue.record("Expected error")
        } catch {
            // Should retry server errors
            #expect(attemptCount == 3)
        }
    }
    
    @Test func testNoRetryClientErrors() async throws {
        var attemptCount = 0
        let policy = RetryPolicy(maxAttempts: 3, baseDelay: 0.01, maxDelay: 0.1)
        
        do {
            _ = try await RetryUtility.execute(policy: policy) {
                attemptCount += 1
                throw NetworkError.unauthorized
            }
            Issue.record("Expected error")
        } catch {
            // Should NOT retry client errors
            #expect(attemptCount == 1)
            #expect(error as? NetworkError == NetworkError.unauthorized)
        }
    }
    
    @Test func testNoRetryForbiddenErrors() async throws {
        var attemptCount = 0
        let policy = RetryPolicy(maxAttempts: 3, baseDelay: 0.01, maxDelay: 0.1)
        
        do {
            _ = try await RetryUtility.execute(policy: policy) {
                attemptCount += 1
                throw NetworkError.forbidden
            }
            Issue.record("Expected error")
        } catch {
            // Should NOT retry forbidden errors
            #expect(attemptCount == 1)
        }
    }
    
    @Test func testNoRetryNotFoundErrors() async throws {
        var attemptCount = 0
        let policy = RetryPolicy(maxAttempts: 3, baseDelay: 0.01, maxDelay: 0.1)
        
        do {
            _ = try await RetryUtility.execute(policy: policy) {
                attemptCount += 1
                throw NetworkError.notFound
            }
            Issue.record("Expected error")
        } catch {
            // Should NOT retry not found errors
            #expect(attemptCount == 1)
        }
    }
    
    // MARK: - Retry Success After Failures Tests
    
    @Test func testSuccessAfterOneRetriableFailure() async throws {
        var attemptCount = 0
        let policy = RetryPolicy(maxAttempts: 3, baseDelay: 0.01, maxDelay: 0.1)
        
        let result = try await RetryUtility.execute(policy: policy) {
            attemptCount += 1
            if attemptCount < 2 {
                throw NetworkError.timeout
            }
            return "Success"
        }
        
        #expect(result == "Success")
        #expect(attemptCount == 2)
    }
    
    @Test func testSuccessAfterMultipleRetriableFailures() async throws {
        var attemptCount = 0
        let policy = RetryPolicy(maxAttempts: 5, baseDelay: 0.01, maxDelay: 0.1)
        
        let result = try await RetryUtility.execute(policy: policy) {
            attemptCount += 1
            if attemptCount < 4 {
                throw NetworkError.noConnection
            }
            return 42
        }
        
        #expect(result == 42)
        #expect(attemptCount == 4)
    }
    
    @Test func testSuccessOnLastAttempt() async throws {
        var attemptCount = 0
        let policy = RetryPolicy(maxAttempts: 3, baseDelay: 0.01, maxDelay: 0.1)
        
        let result = try await RetryUtility.execute(policy: policy) {
            attemptCount += 1
            if attemptCount < 4 { // Succeeds on 4th attempt (1 initial + 3 retries)
                throw NetworkError.timeout
            }
            return "Success"
        }
        
        #expect(result == "Success")
        #expect(attemptCount == 4)
    }
    
    // MARK: - Mixed Error Scenarios Tests
    
    @Test func testRetriableThenNonRetriableError() async throws {
        var attemptCount = 0
        let policy = RetryPolicy(maxAttempts: 5, baseDelay: 0.01, maxDelay: 0.1)
        
        do {
            _ = try await RetryUtility.execute(policy: policy) {
                attemptCount += 1
                if attemptCount <= 2 {
                    throw NetworkError.timeout // Retriable
                }
                throw NetworkError.unauthorized // Non-retriable
            }
            Issue.record("Expected error")
        } catch {
            // Should stop at non-retriable error
            #expect(attemptCount == 3)
            #expect(error as? NetworkError == NetworkError.unauthorized)
        }
    }
    
    @Test func testNonRetriableErrorStopsImmediately() async throws {
        var attemptCount = 0
        let policy = RetryPolicy(maxAttempts: 5, baseDelay: 0.01, maxDelay: 0.1)
        
        do {
            _ = try await RetryUtility.execute(policy: policy) {
                attemptCount += 1
                throw NetworkError.forbidden
            }
            Issue.record("Expected error")
        } catch {
            // Should stop immediately
            #expect(attemptCount == 1)
        }
    }
    
    // MARK: - URLError Retry Tests
    
    @Test func testRetryURLErrorTimeout() async throws {
        var attemptCount = 0
        let policy = RetryPolicy(maxAttempts: 2, baseDelay: 0.01, maxDelay: 0.1)
        
        do {
            _ = try await RetryUtility.execute(policy: policy) {
                attemptCount += 1
                throw URLError(.timedOut)
            }
            Issue.record("Expected error")
        } catch {
            // Should retry URLError timeouts
            #expect(attemptCount == 3)
        }
    }
    
    @Test func testRetryURLErrorNetworkConnectionLost() async throws {
        var attemptCount = 0
        let policy = RetryPolicy(maxAttempts: 2, baseDelay: 0.01, maxDelay: 0.1)
        
        do {
            _ = try await RetryUtility.execute(policy: policy) {
                attemptCount += 1
                throw URLError(.networkConnectionLost)
            }
            Issue.record("Expected error")
        } catch {
            // Should retry network connection lost
            #expect(attemptCount == 3)
        }
    }
    
    @Test func testRetryURLErrorNotConnectedToInternet() async throws {
        var attemptCount = 0
        let policy = RetryPolicy(maxAttempts: 2, baseDelay: 0.01, maxDelay: 0.1)
        
        do {
            _ = try await RetryUtility.execute(policy: policy) {
                attemptCount += 1
                throw URLError(.notConnectedToInternet)
            }
            Issue.record("Expected error")
        } catch {
            // Should retry not connected errors
            #expect(attemptCount == 3)
        }
    }
    
    @Test func testNoRetryURLErrorCancelled() async throws {
        var attemptCount = 0
        let policy = RetryPolicy(maxAttempts: 3, baseDelay: 0.01, maxDelay: 0.1)
        
        do {
            _ = try await RetryUtility.execute(policy: policy) {
                attemptCount += 1
                throw URLError(.cancelled)
            }
            Issue.record("Expected error")
        } catch {
            // Should NOT retry cancelled errors
            #expect(attemptCount == 1)
        }
    }
    
    @Test func testNoRetryURLErrorBadURL() async throws {
        var attemptCount = 0
        let policy = RetryPolicy(maxAttempts: 3, baseDelay: 0.01, maxDelay: 0.1)
        
        do {
            _ = try await RetryUtility.execute(policy: policy) {
                attemptCount += 1
                throw URLError(.badURL)
            }
            Issue.record("Expected error")
        } catch {
            // Should NOT retry bad URL errors
            #expect(attemptCount == 1)
        }
    }
    
    // MARK: - Exponential Backoff Timing Tests
    
    @Test func testExponentialBackoffTiming() async throws {
        let policy = RetryPolicy(maxAttempts: 3, baseDelay: 0.05, maxDelay: 1.0)
        var attemptCount = 0
        var timestamps: [Date] = []
        
        do {
            _ = try await RetryUtility.execute(policy: policy) {
                timestamps.append(Date())
                attemptCount += 1
                throw NetworkError.timeout
            }
            Issue.record("Expected error")
        } catch {
            #expect(attemptCount == 4)
            #expect(timestamps.count == 4)
            
            // Verify delays increase exponentially
            if timestamps.count >= 2 {
                let delay1 = timestamps[1].timeIntervalSince(timestamps[0])
                #expect(delay1 >= 0.04 && delay1 <= 0.15)
            }
            
            if timestamps.count >= 3 {
                let delay2 = timestamps[2].timeIntervalSince(timestamps[1])
                #expect(delay2 >= 0.08 && delay2 <= 0.25)
            }
        }
    }
    
    // MARK: - Zero Retry Policy Tests
    
    @Test func testZeroRetriesFailsImmediately() async throws {
        var attemptCount = 0
        let policy = RetryPolicy.none
        
        do {
            _ = try await RetryUtility.execute(policy: policy) {
                attemptCount += 1
                throw NetworkError.timeout
            }
            Issue.record("Expected error")
        } catch {
            // Should fail immediately with no retries
            #expect(attemptCount == 1)
        }
    }
    
    // MARK: - Concurrent Retry Operations Tests
    
    @Test func testMultipleConcurrentRetryOperations() async throws {
        let policy = RetryPolicy(maxAttempts: 2, baseDelay: 0.01, maxDelay: 0.1)
        var count1 = 0
        var count2 = 0
        var count3 = 0
        
        // Run multiple retry operations concurrently
        async let result1: String = {
            try await RetryUtility.execute(policy: policy) {
                count1 += 1
                if count1 < 2 {
                    throw NetworkError.timeout
                }
                return "Result1"
            }
        }()
        
        async let result2: String = {
            try await RetryUtility.execute(policy: policy) {
                count2 += 1
                if count2 < 3 {
                    throw NetworkError.noConnection
                }
                return "Result2"
            }
        }()
        
        async let result3: String = {
            try await RetryUtility.execute(policy: policy) {
                count3 += 1
                return "Result3"
            }
        }()
        
        let (r1, r2, r3) = try await (result1, result2, result3)
        
        #expect(r1 == "Result1")
        #expect(r2 == "Result2")
        #expect(r3 == "Result3")
        #expect(count1 == 2)
        #expect(count3 == 1)
    }
}
