# Blocked User (HTTP 403) Global Handling Implementation

## Overview
This document describes the implementation of centralized blocked user handling in the iOS app. When the backend blocks a user and returns HTTP 403 Forbidden for authenticated requests, the app now handles this globally, logging out the user and showing an appropriate alert.

## Architecture

### 1. HTTPStatus Enum (`Networking/HTTPStatus.swift`)
A centralized enum that provides HTTP status code constants, following clean code principles by eliminating magic numbers.

```swift
enum HTTPStatus {
    static let ok = 200
    static let created = 201
    static let successRange = 200...299
    static let unauthorized = 401
    static let forbidden = 403
    static let notFound = 404
    static let timeout = 408
}
```

**Benefits:**
- No magic numbers in code
- Type-safe status code handling
- Easy to maintain and extend

### 2. BlockedUserHandler (`Networking/BlockedUserHandler.swift`)
A thread-safe handler that manages blocked user responses with concurrency safety.

**Key Features:**
- **Thread-safe:** Handler methods use `@MainActor` to ensure UI updates happen on the main thread
- **Single execution:** Prevents duplicate logout calls when multiple 403 responses arrive simultaneously
- **Protocol-based:** `BlockedUserHandlerProtocol` for testability and dependency injection
- **Stateful guard:** Uses `isHandlingBlock` flag to prevent re-execution

```swift
class BlockedUserHandler: BlockedUserHandlerProtocol {
    private var isHandlingBlock = false
    var onBlockedUser: (@MainActor () -> Void)?
    
    @MainActor
    func handleBlockedUser() {
        guard !isHandlingBlock else { return }
        isHandlingBlock = true
        onBlockedUser?()
    }
}
```

### 3. NetworkClient Integration (`Networking/NetworkClient.swift`)
The centralized networking layer now intercepts 403 responses and triggers the blocked user handler.

**Changes:**
1. Added `blockedUserHandler` property
2. Added `configureBlockedUserHandler()` method for dependency injection
3. Modified status code handling to use `HTTPStatus` constants
4. Added 403 interception before throwing `NetworkError.forbidden`

```swift
case HTTPStatus.forbidden:
    // Handle blocked user globally before throwing error
    await blockedUserHandler.handleBlockedUser()
    throw NetworkError.forbidden
```

**Flow:**
1. Network request receives 403 status code
2. `blockedUserHandler.handleBlockedUser()` is called
3. Handler executes the configured callback
4. `NetworkError.forbidden` is thrown (for backward compatibility)

### 4. AuthState Enhancement (`Models/AuthState.swift`)
Added blocked user handling logic to the authentication state manager.

**New Property:**
- `@Published var showBlockedUserAlert: Bool` - Controls alert presentation

**New Method:**
```swift
func handleBlockedUser() {
    Logger.network.warning("Handling blocked user - logging out")
    self.showBlockedUserAlert = true
    logout()
}
```

**Behavior:**
1. Sets alert flag to trigger UI alert
2. Calls existing `logout()` method
3. Clears all authentication data:
   - User object
   - Auth token (from Keychain)
   - UserDefaults entries
   - Session state

### 5. App-Level Integration (`AnonymousWallIosApp.swift`)
The main app file configures the blocked user handler at startup and presents the alert.

**Configuration:**
```swift
init() {
    // ... existing initialization ...
    
    Task { @MainActor in
        NetworkClient.shared.configureBlockedUserHandler {
            authState.handleBlockedUser()
        }
    }
}
```

**Alert Presentation:**
```swift
.alert("Account Blocked", isPresented: $authState.showBlockedUserAlert) {
    Button("OK", role: .cancel) { }
} message: {
    Text("Your account has been blocked. Please contact support.")
}
```

## Concurrency Safety

### Thread Safety Mechanisms
1. **@MainActor on methods:** Handler methods are annotated with `@MainActor` ensuring execution on main thread for UI updates
2. **State Guard:** `isHandlingBlock` flag prevents re-execution
3. **Swift Concurrency:** Uses async/await for safe asynchronous operations

### Multiple Concurrent 403 Handling
When multiple API calls fail with 403 simultaneously:
1. First call acquires the handler lock (`isHandlingBlock = false → true`)
2. Subsequent calls are blocked by the guard and return early
3. Only one logout sequence executes
4. Only one alert is shown to the user

## Testing

### Test Coverage (`BlockedUserHandlerTests.swift`)
Comprehensive test suite covering all scenarios:

1. **Basic Functionality:**
   - `testHandleBlockedUserTriggersCallback` - Verifies callback execution
   
2. **Concurrency Safety:**
   - `testHandleBlockedUserOnlyExecutesOnce` - Sequential duplicate prevention
   - `testConcurrentBlockedUserCallsOnlyExecuteOnce` - Concurrent duplicate prevention (uses TaskGroup)
   
3. **Testing Support:**
   - `testHandleBlockedUserCanBeResetForTesting` - Reset functionality for test isolation

4. **Integration Tests:**
   - `AuthStateBlockedUserTests` - Tests AuthState.handleBlockedUser()
   - `testHandleBlockedUserLogsOutUser` - Verifies complete logout
   - `testHandleBlockedUserSetsAlertFlag` - Verifies alert trigger
   - `testHandleBlockedUserClearsPersistedState` - Verifies data cleanup
   - `testRegularLogoutDoesNotSetBlockedUserAlert` - Ensures separation of concerns

5. **Infrastructure Tests:**
   - `HTTPStatusTests` - Validates HTTPStatus enum constants

### Running Tests
```bash
xcodebuild test -scheme AnonymousWallIos \
  -destination 'platform=iOS Simulator,name=iPhone 15'
```

## SOLID Principles Compliance

### Single Responsibility Principle (SRP)
- **BlockedUserHandler:** Only handles blocked user logic
- **AuthState:** Manages authentication state
- **NetworkClient:** Handles HTTP communication

### Open/Closed Principle (OCP)
- Handler uses protocol for extensibility
- New status codes can be added to HTTPStatus without modifying existing code

### Liskov Substitution Principle (LSP)
- `BlockedUserHandlerProtocol` allows for mock implementations in tests
- Protocol-based design enables substitution

### Interface Segregation Principle (ISP)
- `BlockedUserHandlerProtocol` has a single focused method
- No forced dependencies on unused methods

### Dependency Inversion Principle (DIP)
- High-level modules (App) depend on abstractions (protocol)
- NetworkClient depends on BlockedUserHandler abstraction
- Closure-based callback for decoupling

## Security Considerations

### Data Cleanup on Block
When a user is blocked, ALL authentication data is cleared:
- ✅ JWT token removed from Keychain
- ✅ User object cleared from memory
- ✅ UserDefaults entries removed
- ✅ Session state reset to unauthenticated

### No Sensitive Data Leakage
- Alert message is generic ("contact support")
- No specific reason for block is revealed
- Logs contain minimal information

## User Experience

### User Flow on Block
1. User makes authenticated API request
2. Backend returns 403 Forbidden
3. App immediately logs out user
4. Navigation automatically resets to login screen (via `authState.isAuthenticated = false`)
5. Alert appears: "Your account has been blocked. Please contact support."
6. User taps "OK" to dismiss alert
7. User is on login screen, must contact support

### Navigation Behavior
The navigation reset is handled automatically by SwiftUI's state-driven UI:
```swift
var body: some Scene {
    WindowGroup {
        if authState.isAuthenticated {
            TabBarView(...) // User in app
        } else {
            AuthenticationView(...) // Login screen
        }
    }
}
```

When `authState.isAuthenticated` becomes `false`, SwiftUI automatically:
- Removes the TabBarView
- Shows the AuthenticationView
- Clears the navigation stack
- No memory leaks (SwiftUI manages view lifecycle)

## Code Quality

### SwiftLint Compliance
All code follows the project's SwiftLint rules:
- Line length < 150 characters
- Proper naming conventions
- No force unwrapping in production code
- Appropriate access control

### Documentation
- All public APIs have doc comments
- Complex logic is explained with inline comments
- Architecture decisions are documented

## Future Enhancements

### Potential Improvements
1. **Analytics:** Track blocked user events for monitoring
2. **Retry Logic:** Distinguish between temporary blocks and permanent bans
3. **Offline Support:** Handle 403 when device comes back online
4. **Custom Block Messages:** Support server-provided block reasons
5. **Appeal Process:** Link to appeal form in alert

## Summary

This implementation provides:
- ✅ Centralized 403 handling at network layer
- ✅ Thread-safe concurrency handling
- ✅ Complete session cleanup
- ✅ User-friendly alert presentation
- ✅ Automatic navigation reset
- ✅ SOLID principles compliance
- ✅ Comprehensive test coverage
- ✅ No code duplication
- ✅ Clean separation of concerns
- ✅ Production-ready security

The solution is minimal, focused, and follows iOS best practices while meeting all requirements specified in the issue.
