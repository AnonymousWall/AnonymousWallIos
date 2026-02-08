# Mock Services for Unit Testing

This directory contains mock implementations of service protocols for fast, deterministic unit testing without network or backend dependencies.

## Overview

The mock services in this directory implement the same protocols as the real services (`AuthServiceProtocol` and `PostServiceProtocol`), making them drop-in replacements for testing purposes.

## Mock Services

### MockAuthService

Mock implementation of `AuthServiceProtocol` with configurable stub responses.

**Features:**
- ✅ Implements all 9 authentication methods
- ✅ Configurable behavior per method (success, failure, empty state)
- ✅ Call tracking to verify method invocations
- ✅ Customizable responses via properties
- ✅ Helper methods for batch configuration

**Example Usage:**

```swift
// Success scenario (default)
let mockAuth = MockAuthService()
let response = try await mockAuth.loginWithPassword(email: "test@example.com", password: "password")
// Returns: AuthResponse with mock token and user

// Failure scenario
mockAuth.loginWithPasswordBehavior = .failure(MockAuthService.MockError.invalidCredentials)
// Will throw: MockAuthService.MockError.invalidCredentials

// Empty state scenario
mockAuth.registerWithEmailBehavior = .emptyState
// Returns: AuthResponse with empty strings

// Custom response
mockAuth.mockUser = User(id: "custom-id", email: "custom@example.com", ...)
// Returns: Your custom user object

// Batch configuration
mockAuth.configureAllToFail(with: MockAuthService.MockError.networkError)
mockAuth.configureAllToEmptyState()
mockAuth.resetBehaviors() // Reset to success
mockAuth.resetCallTracking() // Reset call flags
```

### MockPostService

Mock implementation of `PostServiceProtocol` with configurable stub responses.

**Features:**
- ✅ Implements all 12 post/comment/user methods
- ✅ Configurable behavior per method (success, failure, empty state)
- ✅ Call tracking to verify method invocations
- ✅ Maintains internal state (mockPosts, mockComments arrays)
- ✅ Customizable responses via properties
- ✅ Helper methods for batch configuration

**Example Usage:**

```swift
// Success scenario with mock data
let mockPost = MockPostService()
mockPost.mockPosts = [Post(...), Post(...)]
let response = try await mockPost.fetchPosts(...)
// Returns: PostListResponse with mockPosts

// Failure scenario
mockPost.createPostBehavior = .failure(MockPostService.MockError.unauthorized)
// Will throw: MockPostService.MockError.unauthorized

// Empty state scenario
mockPost.fetchPostsBehavior = .emptyState
// Returns: Empty PostListResponse

// Stateful behavior
_ = try await mockPost.createPost(title: "Test", content: "Content", ...)
// Automatically adds post to mockPosts array

// Batch configuration
mockPost.configureAllToFail(with: MockPostService.MockError.networkError)
mockPost.configureAllToEmptyState()
mockPost.resetBehaviors() // Reset to success
mockPost.clearMockData() // Clear mockPosts and mockComments
mockPost.resetCallTracking() // Reset call flags
```

## Configuration Options

### MockBehavior Enum

All mock methods support three behavior modes:

1. **`.success`** - Returns successful mock responses (default)
2. **`.failure(Error)`** - Throws the specified error
3. **`.emptyState`** - Returns responses with empty/zero values

### Call Tracking

Each method has a corresponding boolean flag to track invocations:

```swift
// MockAuthService
mockAuth.loginWithPasswordCalled // true if called
mockAuth.registerWithEmailCalled // true if called
// ... etc

// MockPostService
mockPost.createPostCalled // true if called
mockPost.fetchPostsCalled // true if called
// ... etc
```

## Testing Patterns

### Protocol-Based Dependency Injection

```swift
func performAuthOperation(authService: AuthServiceProtocol) async throws {
    // Can accept real AuthService or MockAuthService
    return try await authService.loginWithPassword(...)
}

// In tests
let mockAuth = MockAuthService()
try await performAuthOperation(authService: mockAuth)
```

### Testing Success Paths

```swift
@Test func testSuccessfulLogin() async throws {
    let mockAuth = MockAuthService()
    let response = try await mockAuth.loginWithPassword(email: "test@test.com", password: "pass")
    #expect(response.accessToken == "mock-token")
    #expect(mockAuth.loginWithPasswordCalled == true)
}
```

### Testing Failure Paths

```swift
@Test func testLoginFailure() async throws {
    let mockAuth = MockAuthService()
    mockAuth.loginWithPasswordBehavior = .failure(MockAuthService.MockError.invalidCredentials)
    
    do {
        _ = try await mockAuth.loginWithPassword(email: "test@test.com", password: "wrong")
        Issue.record("Expected error to be thrown")
    } catch {
        // Error thrown as expected
    }
}
```

### Testing Empty States

```swift
@Test func testEmptyPostList() async throws {
    let mockPost = MockPostService()
    mockPost.fetchPostsBehavior = .emptyState
    
    let response = try await mockPost.fetchPosts(...)
    #expect(response.data.isEmpty)
    #expect(response.pagination.total == 0)
}
```

## Benefits

- **Fast** - No network calls, instant responses
- **Deterministic** - Consistent, predictable test results
- **Isolated** - Tests don't depend on external services
- **Flexible** - Easy to configure for any scenario
- **Comprehensive** - Covers success, failure, and edge cases

## See Also

- `AnonymousWallIosTests/ServiceProtocolTests.swift` - Example test cases
- `Protocols/AuthServiceProtocol.swift` - Auth service interface
- `Protocols/PostServiceProtocol.swift` - Post service interface
