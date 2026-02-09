# Logger Usage Guide

## Overview

The `Logger` provides a centralized, structured logging infrastructure for the AnonymousWall iOS app. It wraps Apple's `os.log` framework and provides a unified interface for logging at different severity levels.

## Features

- **Structured Logging**: Uses `os.log` for system-level integration (visible in Console.app and Xcode)
- **Multiple Log Levels**: Debug, Info, Warning, Error
- **Environment-Aware**: Automatically respects `AppConfiguration.enableLogging` setting
- **Category-Based**: Organize logs by functional area (Networking, Authentication, UI, etc.)
- **File Context**: Automatically includes file, function, and line number information
- **Dual Output**: In development, logs appear both in os.log and console output

## Basic Usage

### Using Convenience Loggers

The easiest way to use the logger is with the pre-defined convenience loggers:

```swift
// Network operations
Logger.network.debug("Starting API request to /posts")
Logger.network.info("Request completed successfully")
Logger.network.warning("Rate limit approaching")
Logger.network.error("Network request failed: \(error)")

// Authentication operations
Logger.auth.info("User logged in successfully")
Logger.auth.warning("Invalid token detected")
Logger.auth.error("Authentication failed: \(error)")

// UI operations
Logger.ui.debug("View appeared: HomeView")
Logger.ui.info("User tapped create post button")

// Data operations
Logger.data.debug("Fetching from cache")
Logger.data.warning("Cache miss for key: \(key)")

// General operations
Logger.general.info("App launched")
```

### Creating Custom Loggers

You can create a logger with a custom category:

```swift
let logger = Logger(category: "PaymentProcessing")
logger.info("Processing payment for user: \(userId)")
logger.error("Payment failed: \(error)")
```

### Creating Loggers with Custom Subsystem

For modules or frameworks, you can specify both subsystem and category:

```swift
let logger = Logger(subsystem: "com.mycompany.myframework", category: "Sync")
logger.debug("Starting sync operation")
```

## Log Levels

### Debug 🔍
Use for detailed diagnostic information useful during development:

```swift
Logger.network.debug("Request headers: \(headers)")
Logger.data.debug("Cache contains \(count) items")
```

### Info ℹ️
Use for general informational messages about app state:

```swift
Logger.auth.info("User logged in successfully")
Logger.ui.info("View transitioned to HomeView")
```

### Warning ⚠️
Use for potentially problematic situations that don't prevent operation:

```swift
Logger.network.warning("API response took \(duration)s (expected < 2s)")
Logger.data.warning("Cache size exceeds recommended limit")
```

### Error ❌
Use for error conditions that prevent normal operation:

```swift
Logger.network.error("Failed to connect to server: \(error)")
Logger.auth.error("Token validation failed: \(error)")
```

## Environment Configuration

Logging behavior is controlled by `AppConfiguration`:

- **Development**: Logging enabled, output to both os.log and console
- **Staging**: Logging enabled, output to os.log only
- **Production**: Logging disabled by default (can be enabled for debugging)

## Best Practices

1. **Choose the Right Level**: Use appropriate log levels for the situation
2. **Be Descriptive**: Include relevant context in your messages
3. **Avoid Logging Sensitive Data**: Don't log passwords, tokens, or personal information
4. **Use Categories**: Create loggers with meaningful categories for better organization
5. **Log Errors**: Always log errors with sufficient context for debugging

## Examples from the Codebase

### NetworkClient.swift

```swift
private func logRequest(_ request: URLRequest) {
    guard config.enableLogging else { return }
    
    let logger = Logger.network
    var message = "Request\n   URL: \(request.url?.absoluteString ?? "unknown")\n   Method: \(request.httpMethod ?? "GET")"
    
    if let headers = request.allHTTPHeaderFields, !headers.isEmpty {
        message += "\n   Headers: \(headers)"
    }
    
    logger.debug(message)
}
```

### PostService.swift

```swift
} catch {
    Logger.data.warning("Failed to decode PostListResponse: \(error.localizedDescription)")
    throw error
}
```

## Viewing Logs

### In Xcode
- Logs appear in the Xcode console during development
- Use the search/filter feature to find specific categories or messages

### In Console.app
1. Open Console.app on macOS
2. Connect your iOS device or select the simulator
3. Filter by subsystem: `com.anonymouswall.ios`
4. Filter by category: `Networking`, `Authentication`, `UI`, etc.

### Using Instruments
1. Open Instruments
2. Select the "Logging" template
3. Filter by subsystem and category to analyze log patterns

## Migration from print()

Replace existing `print()` statements with appropriate Logger calls:

```swift
// Before
print("User logged in: \(userId)")

// After
Logger.auth.info("User logged in: \(userId)")
```

```swift
// Before
print("⚠️ Network error: \(error)")

// After
Logger.network.error("Network error: \(error)")
```

## Available Convenience Loggers

| Logger | Category | Use For |
|--------|----------|---------|
| `Logger.network` | Networking | API requests, responses, network errors |
| `Logger.auth` | Authentication | Login, logout, token management |
| `Logger.ui` | UI | View lifecycle, user interactions |
| `Logger.data` | Data | Data persistence, caching, CoreData |
| `Logger.general` | General | App lifecycle, general operations |
