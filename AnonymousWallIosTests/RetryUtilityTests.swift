//
//  RetryUtilityTests.swift
//  AnonymousWallIosTests
//
//  Tests for RetryUtility async retry behavior
//

import Testing
@testable import AnonymousWallIos
import Foundation

struct RetryUtilityTests {
    
    // MARK: - Success Tests
    
    @Test func testSuccessfulOperationNoRetry() async throws {
        var attemptCount = 0
        
        let result = try await RetryUtility.execute(policy: .default) {
            attemptCount += 1
            return "Success"
        }
        
        #expect(result == "Success")
        #expect(attemptCount == 1)
    }
    
    @Test func testSuccessAfterOneRetry() async throws {
        var attemptCount = 0
        
        let result = try await RetryUtility.execute(policy: .default) {
            attemptCount += 1
            if attemptCount < 2 {
                throw NetworkError.timeout
            }
            return "Success"
        }
        
        #expect(result == "Success")
        #expect(attemptCount == 2)
    }
    
    @Test func testSuccessAfterMultipleRetries() async throws {
        var attemptCount = 0
        
        let result = try await RetryUtility.execute(policy: .default) {
            attemptCount += 1
            if attemptCount < 3 {
                throw NetworkError.noConnection
            }
            return 42
        }
        
        #expect(result == 42)
        #expect(attemptCount == 3)
    }
    
    // MARK: - Retry Exhaustion Tests
    
    @Test func testRetriesExhausted() async throws {
        var attemptCount = 0
        let policy = RetryPolicy(maxAttempts: 2, baseDelay: 0.01, maxDelay: 0.1)
        
        do {
            _ = try await RetryUtility.execute(policy: policy) {
                attemptCount += 1
                throw NetworkError.timeout
            }
            Issue.record("Expected error to be thrown")
        } catch {
            // Should attempt 3 times (1 initial + 2 retries)
            #expect(attemptCount == 3)
            #expect(error as? NetworkError == NetworkError.timeout)
        }
    }
    
    @Test func testNoRetryPolicy() async throws {
        var attemptCount = 0
        
        do {
            _ = try await RetryUtility.execute(policy: .none) {
                attemptCount += 1
                throw NetworkError.timeout
            }
            Issue.record("Expected error to be thrown")
        } catch {
            // Should only attempt once (no retries)
            #expect(attemptCount == 1)
        }
    }
    
    // MARK: - Non-Retriable Error Tests
    
    @Test func testNonRetriableErrorNotRetried() async throws {
        var attemptCount = 0
        let policy = RetryPolicy(maxAttempts: 3, baseDelay: 0.01, maxDelay: 0.1)
        
        do {
            _ = try await RetryUtility.execute(policy: policy) {
                attemptCount += 1
                throw NetworkError.unauthorized
            }
            Issue.record("Expected error to be thrown")
        } catch {
            // Should only attempt once (unauthorized is not retriable)
            #expect(attemptCount == 1)
            #expect(error as? NetworkError == NetworkError.unauthorized)
        }
    }
    
    @Test func testClientErrorNotRetried() async throws {
        var attemptCount = 0
        let policy = RetryPolicy(maxAttempts: 3, baseDelay: 0.01, maxDelay: 0.1)
        
        do {
            _ = try await RetryUtility.execute(policy: policy) {
                attemptCount += 1
                throw NetworkError.notFound
            }
            Issue.record("Expected error to be thrown")
        } catch {
            // Should only attempt once (404 is not retriable)
            #expect(attemptCount == 1)
            #expect(error as? NetworkError == NetworkError.notFound)
        }
    }
    
    @Test func testCancelledErrorNotRetried() async throws {
        var attemptCount = 0
        let policy = RetryPolicy(maxAttempts: 3, baseDelay: 0.01, maxDelay: 0.1)
        
        do {
            _ = try await RetryUtility.execute(policy: policy) {
                attemptCount += 1
                throw NetworkError.cancelled
            }
            Issue.record("Expected error to be thrown")
        } catch {
            // Should only attempt once (cancelled should not retry)
            #expect(attemptCount == 1)
            #expect(error as? NetworkError == NetworkError.cancelled)
        }
    }
    
    // MARK: - Retriable Error Tests
    
    @Test func testTimeoutIsRetried() async throws {
        var attemptCount = 0
        let policy = RetryPolicy(maxAttempts: 2, baseDelay: 0.01, maxDelay: 0.1)
        
        do {
            _ = try await RetryUtility.execute(policy: policy) {
                attemptCount += 1
                throw NetworkError.timeout
            }
            Issue.record("Expected error to be thrown")
        } catch {
            // Should retry timeout errors
            #expect(attemptCount == 3)
        }
    }
    
    @Test func testNoConnectionIsRetried() async throws {
        var attemptCount = 0
        let policy = RetryPolicy(maxAttempts: 2, baseDelay: 0.01, maxDelay: 0.1)
        
        do {
            _ = try await RetryUtility.execute(policy: policy) {
                attemptCount += 1
                throw NetworkError.noConnection
            }
            Issue.record("Expected error to be thrown")
        } catch {
            // Should retry no connection errors
            #expect(attemptCount == 3)
        }
    }
    
    @Test func testServerErrorIsRetried() async throws {
        var attemptCount = 0
        let policy = RetryPolicy(maxAttempts: 2, baseDelay: 0.01, maxDelay: 0.1)
        
        do {
            _ = try await RetryUtility.execute(policy: policy) {
                attemptCount += 1
                throw NetworkError.serverError("Server error: 500")
            }
            Issue.record("Expected error to be thrown")
        } catch {
            // Should retry server errors (5xx)
            #expect(attemptCount == 3)
        }
    }
    
    // MARK: - Delay Tests
    
    @Test func testExponentialBackoffDelay() async throws {
        let policy = RetryPolicy(maxAttempts: 3, baseDelay: 0.05, maxDelay: 1.0)
        var attemptCount = 0
        var timestamps: [Date] = []
        
        do {
            _ = try await RetryUtility.execute(policy: policy) {
                timestamps.append(Date())
                attemptCount += 1
                throw NetworkError.timeout
            }
            Issue.record("Expected error to be thrown")
        } catch {
            #expect(attemptCount == 4)
            #expect(timestamps.count == 4)
            
            // Check that delays are approximately correct
            if timestamps.count >= 2 {
                let delay1 = timestamps[1].timeIntervalSince(timestamps[0])
                // First retry delay should be ~0.05s (baseDelay * 2^0)
                #expect(delay1 >= 0.04)
                #expect(delay1 <= 0.15)
            }
            
            if timestamps.count >= 3 {
                let delay2 = timestamps[2].timeIntervalSince(timestamps[1])
                // Second retry delay should be ~0.1s (baseDelay * 2^1)
                #expect(delay2 >= 0.08)
                #expect(delay2 <= 0.25)
            }
        }
    }
    
    // MARK: - Cancellation Tests
    
    @Test func testCancellationDuringRetry() async throws {
        let policy = RetryPolicy(maxAttempts: 10, baseDelay: 0.5, maxDelay: 5.0)
        var attemptCount = 0
        
        let task = Task {
            try await RetryUtility.execute(policy: policy) {
                attemptCount += 1
                throw NetworkError.timeout
            }
        }
        
        // Cancel the task after a short delay
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        task.cancel()
        
        do {
            _ = try await task.value
            Issue.record("Expected cancellation error")
        } catch {
            // Should have been cancelled during retry delay
            #expect(attemptCount <= 3)
        }
    }
    
    // MARK: - Complex Scenarios
    
    @Test func testMixedErrorTypes() async throws {
        var attemptCount = 0
        let policy = RetryPolicy(maxAttempts: 5, baseDelay: 0.01, maxDelay: 0.1)
        
        do {
            _ = try await RetryUtility.execute(policy: policy) {
                attemptCount += 1
                
                // First two attempts: retriable errors
                if attemptCount <= 2 {
                    throw NetworkError.timeout
                }
                // Third attempt: non-retriable error
                throw NetworkError.unauthorized
            }
            Issue.record("Expected error to be thrown")
        } catch {
            // Should stop at the non-retriable error
            #expect(attemptCount == 3)
            #expect(error as? NetworkError == NetworkError.unauthorized)
        }
    }
    
    @Test func testReturnValuePreserved() async throws {
        struct ComplexResult: Equatable {
            let id: String
            let count: Int
        }
        
        var attemptCount = 0
        let expected = ComplexResult(id: "test-123", count: 42)
        
        let result = try await RetryUtility.execute(policy: .default) {
            attemptCount += 1
            if attemptCount < 2 {
                throw NetworkError.noConnection
            }
            return expected
        }
        
        #expect(result == expected)
        #expect(attemptCount == 2)
    }
}
