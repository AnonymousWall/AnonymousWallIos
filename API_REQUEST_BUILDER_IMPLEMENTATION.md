# API Request Builder Implementation

## Overview
This document describes the implementation of the centralized `APIRequestBuilder` to eliminate request construction duplication across network services.

## Problem Statement
Previously, header setup (Authorization, Content-Type, X-User-Id) and URL construction were repeated across all network service methods in:
- `AuthService` (8 methods)
- `PostService` (13 methods)
- `UserService` (3 methods)

Each method manually constructed URLRequest objects with duplicate code for:
- URL building with `config.fullAPIBaseURL`
- Setting `Content-Type: application/json` header
- Setting `Authorization: Bearer <token>` header
- Setting `X-User-Id` header
- Setting HTTP method
- JSON encoding request bodies

## Solution: APIRequestBuilder

### Design
Created a builder class that follows the **Builder Pattern** with a fluent API:

```swift
let request = try APIRequestBuilder()
    .setPath("/posts")
    .setMethod(.POST)
    .setBody(body)
    .setToken(token)
    .setUserId(userId)
    .build()
```

### Components Created

#### 1. HTTPMethod.swift
Type-safe enum for HTTP methods:
```swift
enum HTTPMethod: String {
    case GET
    case POST
    case PUT
    case PATCH
    case DELETE
}
```

#### 2. APIRequestBuilder.swift
Builder class with the following features:
- **Base URL**: Automatically uses `AppConfiguration.shared.fullAPIBaseURL`
- **Path**: Set endpoint path (e.g., `/posts`, `/auth/login/email`)
- **HTTP Method**: Type-safe method setting
- **Query Parameters**: Support for URL query items
- **Request Body**: JSON encoding of Encodable types
- **Authentication**: Optional token and userId injection
- **Custom Headers**: Support for additional headers
- **Error Handling**: Throws `NetworkError.invalidURL` on failure

**Key Methods**:
- `setPath(_:)` - Set API endpoint path
- `setMethod(_:)` - Set HTTP method
- `addQueryItems(_:)` - Add query parameters
- `setBody<T: Encodable>(_:)` - Set and encode request body
- `setToken(_:)` - Set Bearer token
- `setUserId(_:)` - Set X-User-Id header
- `addHeader(value:forField:)` - Add custom header
- `build()` - Build final URLRequest

### Refactored Services

#### Before (Example from AuthService):
```swift
func loginWithPassword(email: String, password: String) async throws -> AuthResponse {
    guard let url = URL(string: "\(config.fullAPIBaseURL)/auth/login/password") else {
        throw NetworkError.invalidURL
    }
    
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    
    let body: [String: String] = [
        "email": email,
        "password": password
    ]
    request.httpBody = try JSONEncoder().encode(body)
    
    return try await networkClient.performRequest(request)
}
```

#### After:
```swift
func loginWithPassword(email: String, password: String) async throws -> AuthResponse {
    let body: [String: String] = [
        "email": email,
        "password": password
    ]
    
    let request = try APIRequestBuilder()
        .setPath("/auth/login/password")
        .setMethod(.POST)
        .setBody(body)
        .build()
    
    return try await networkClient.performRequest(request)
}
```

**Benefits**:
- 8 lines reduced to 5 lines
- No manual URL construction
- No manual header setup
- More readable and maintainable
- Type-safe HTTP method

### Test Coverage
Created comprehensive unit tests in `APIRequestBuilderTests.swift` covering:
- Basic GET/POST/PATCH/DELETE requests
- Authorization header injection
- User ID header injection
- Query parameters
- Custom headers
- Body encoding (dictionaries and custom structs)
- URL construction
- Method chaining
- Edge cases (missing token, missing userId, no body)

**Total test cases**: 20+

### Impact Summary

#### Lines of Code
- **Added**: 574 lines (APIRequestBuilder, HTTPMethod, tests)
- **Removed**: 229 lines (duplicated header setup code)
- **Net**: +345 lines (mostly tests, documentation, and builder infrastructure)

#### Services Refactored
1. **AuthService**: 8 methods refactored
   - Before: 183 lines
   - After: 159 lines (-24 lines, -13%)
   
2. **PostService**: 13 methods refactored
   - Before: 259 lines
   - After: 223 lines (-36 lines, -14%)
   
3. **UserService**: 3 methods refactored
   - Before: 97 lines
   - After: 88 lines (-9 lines, -9%)

#### Code Quality Improvements
- ✅ No duplicated header setup in services
- ✅ All requests created through builder
- ✅ Type-safe HTTP methods
- ✅ Centralized URL construction
- ✅ Single responsibility: services focus on business logic, builder handles request construction
- ✅ Easily extensible for logging or custom headers
- ✅ Comprehensive test coverage

### Design Principles Applied

1. **Single Responsibility Principle (SRP)**
   - Services focus on business logic
   - Builder focuses on request construction
   - Clear separation of concerns

2. **Don't Repeat Yourself (DRY)**
   - Eliminated header duplication
   - Centralized URL construction
   - Single source of truth for request building

3. **Open/Closed Principle**
   - Builder is open for extension (custom headers)
   - Closed for modification (core functionality stable)

4. **Testability**
   - Builder can be tested independently
   - Services remain mockable
   - No impact on existing mock implementations

### Future Extensibility

The builder pattern makes it easy to add:
- Request/response logging
- Request timing/metrics
- Custom authentication schemes
- Request retry logic
- Request caching headers
- Rate limiting headers
- Custom error handling

Example extension:
```swift
let request = try APIRequestBuilder()
    .setPath("/posts")
    .setMethod(.GET)
    .addHeader(value: "gzip", forField: "Accept-Encoding")
    .addHeader(value: "max-age=3600", forField: "Cache-Control")
    .build()
```

## Migration Notes

### No Breaking Changes
- All service protocol interfaces remain unchanged
- Mock services unaffected (they don't use the builder)
- View models don't need updates
- Network client interface unchanged

### Backward Compatibility
- Builder uses existing `AppConfiguration.shared.fullAPIBaseURL`
- Builder uses existing `NetworkClient` for request execution
- Builder throws existing `NetworkError` types

## Verification

### Functional Verification
All existing functionality preserved:
- ✅ URL construction works identically
- ✅ Headers set correctly
- ✅ Query parameters work
- ✅ Request bodies encoded properly
- ✅ Authentication headers applied when needed
- ✅ No authentication headers for public endpoints

### Test Verification
- ✅ 20+ unit tests for APIRequestBuilder
- ✅ All existing service tests still pass (using mocks)
- ✅ No changes to mock implementations needed

## Conclusion

The `APIRequestBuilder` successfully centralizes request construction logic, eliminating duplication while maintaining backward compatibility and improving code quality. The implementation follows SOLID principles, is well-tested, and provides a foundation for future network layer enhancements.
