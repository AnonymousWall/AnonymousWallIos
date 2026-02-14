# Exponential Backoff Retry Implementation

## Overview

This implementation provides robust networking resilience through automatic retry of transient failures using exponential backoff strategy. The solution is built following iOS engineering best practices with structured concurrency, thread safety, and comprehensive test coverage.

## Architecture

### Components

1. **RetryPolicy** (`RetryPolicy.swift`)
   - Defines retry configuration (max attempts, delays, backoff strategy)
   - Determines which errors are retriable
   - Calculates exponential backoff delays

2. **RetryUtility** (`RetryUtility.swift`)
   - Actor-based utility for thread-safe retry execution
   - Implements async/await retry logic
   - Respects task cancellation

3. **NetworkClient** (`NetworkClient.swift`)
   - Integrated retry support with default policy
   - Backward compatible with existing code

## Features

### ✅ Retry Strategy

**Retriable Errors:**
- Network timeouts (`URLError.timedOut`, `NetworkError.timeout`)
- Connection lost (`URLError.networkConnectionLost`)
- No internet connection (`URLError.notConnectedToInternet`, `NetworkError.noConnection`)
- 5xx server errors (500-599 status codes)

**Non-Retriable Errors:**
- 4xx client errors (400-499 status codes)
- Authentication errors (401 Unauthorized)
- Authorization errors (403 Forbidden)
- Not found errors (404)
- Cancelled requests
- Invalid URL errors
- Decoding errors

### ⚙️ Configuration

**Default Policy:**
```swift
RetryPolicy.default
// - maxAttempts: 3
// - baseDelay: 0.5 seconds
// - maxDelay: 5.0 seconds
```

**No Retry:**
```swift
RetryPolicy.none
// - maxAttempts: 0
```

**Custom Policy:**
```swift
let customPolicy = RetryPolicy(
    maxAttempts: 5,
    baseDelay: 1.0,
    maxDelay: 10.0
)
```

### 📈 Exponential Backoff

Delay calculation: `baseDelay * 2^attempt`

Example with default policy (baseDelay = 0.5s):
- Attempt 1: 0.5s delay
- Attempt 2: 1.0s delay
- Attempt 3: 2.0s delay

Delays are capped at `maxDelay` to prevent excessive wait times.

## Usage Examples

### Basic Usage (Default Retry)

All NetworkClient methods now support retry by default:

```swift
// Using NetworkClient directly - automatic retries enabled
let request = try APIRequestBuilder()
    .setPath("/posts")
    .setMethod(.GET)
    .setToken(authToken)
    .build()

let posts: PostsResponse = try await NetworkClient.shared.performRequest(request)
// Will automatically retry on transient failures (timeout, 5xx, connection issues)
```

### Custom Retry Policy

```swift
// Use a custom retry policy for specific requests
let aggressiveRetry = RetryPolicy(
    maxAttempts: 5,
    baseDelay: 1.0,
    maxDelay: 10.0
)

let request = try APIRequestBuilder()
    .setPath("/critical-operation")
    .setMethod(.POST)
    .setToken(authToken)
    .build()

let result: Response = try await NetworkClient.shared.performRequest(
    request,
    retryPolicy: aggressiveRetry
)
```

### Disable Retry

```swift
// For operations that should not be retried
let request = try APIRequestBuilder()
    .setPath("/payment")
    .setMethod(.POST)
    .setToken(authToken)
    .build()

let result: PaymentResponse = try await NetworkClient.shared.performRequest(
    request,
    retryPolicy: .none
)
```

### Using RetryUtility Directly

```swift
// Retry any async operation
let result = try await RetryUtility.execute(policy: .default) {
    // Your async operation here
    return try await someAsyncOperation()
}
```

## Backward Compatibility

All existing code continues to work unchanged. The `retryPolicy` parameter has a default value of `.default`:

```swift
// Before: No retry support
let response = try await NetworkClient.shared.performRequest(request)

// After: Automatic retry with default policy (no code changes needed!)
let response = try await NetworkClient.shared.performRequest(request)
```

## Thread Safety

- **RetryUtility** is an `actor`, ensuring thread-safe retry operations
- All NetworkClient methods are properly isolated with `@MainActor` where needed
- Respects Swift's structured concurrency model

## Cancellation Support

Retry operations respect task cancellation:

```swift
let task = Task {
    try await RetryUtility.execute(policy: .default) {
        return try await longRunningOperation()
    }
}

// Cancel the task - retry will stop during the next delay
task.cancel()
```

## Logging

When `AppConfiguration.shared.enableLogging` is true, retry attempts are logged:

```
🔍 DEBUG: Retrying after 0.5s (attempt 1/3)
🔍 DEBUG: Retrying after 1.0s (attempt 2/3)
```

## Testing

Comprehensive test coverage included:

1. **RetryPolicyTests.swift** (24 tests)
   - Configuration validation
   - Exponential backoff calculations
   - Retry decision logic for all error types

2. **RetryUtilityTests.swift** (15 tests)
   - Success scenarios (with/without retries)
   - Retry exhaustion
   - Non-retriable error handling
   - Cancellation behavior
   - Delay timing verification

3. **RetryIntegrationTests.swift** (12 tests)
   - Integration with NetworkClient
   - Service layer compatibility
   - Structured concurrency validation

## Performance Characteristics

- **No overhead when successful**: Zero delay or extra work for successful requests
- **Efficient backoff**: Exponential strategy prevents server overload
- **Resource friendly**: Actor-based design prevents thread explosion
- **Cancellation-aware**: Stops immediately when task is cancelled

## Best Practices

### When to Use Default Policy
- Most API calls
- Idempotent operations (GET, PUT, DELETE)
- Background sync operations

### When to Use Custom Policy
- Critical operations requiring more retries
- Operations with known slow backend processing
- Bulk operations that benefit from longer delays

### When to Disable Retry
- Non-idempotent operations (POST creating resources)
- Payment processing
- Operations with side effects
- User-initiated cancellations

## Error Handling

```swift
do {
    let result = try await NetworkClient.shared.performRequest(request)
    // Handle success
} catch let error as NetworkError {
    switch error {
    case .timeout:
        // All retries exhausted due to timeout
        showAlert("Network timeout. Please try again.")
    case .noConnection:
        // All retries exhausted due to no connection
        showAlert("No internet connection.")
    case .serverError(let message):
        // Server error after all retries
        showAlert("Server error: \(message)")
    case .unauthorized:
        // Not retried - immediate failure
        navigateToLogin()
    default:
        showAlert("An error occurred: \(error.localizedDescription)")
    }
}
```

## Production Readiness

✅ Thread-safe with actor isolation  
✅ Respects structured concurrency  
✅ Cancellation-safe  
✅ No infinite retries  
✅ No UI blocking  
✅ Comprehensive test coverage  
✅ Backward compatible  
✅ Production logging support  
✅ Follows iOS engineering standards  

## Future Enhancements

Potential improvements for future iterations:
- Jitter addition to prevent thundering herd
- Retry budget per time window
- Circuit breaker pattern
- Retry metrics and monitoring
- Per-endpoint retry configuration
- Adaptive retry based on response headers

## References

- iOS Engineering Standards (MVVM, Thread Safety, Concurrency)
- Swift Structured Concurrency Guide
- HTTP Status Code Specifications (RFC 7231)
- Exponential Backoff Best Practices
