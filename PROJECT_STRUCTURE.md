# Project Structure

This document describes the organization and architecture of the AnonymousWallIos project.

## Directory Structure

```
AnonymousWallIos/
├── AnonymousWallIos/
│   ├── AnonymousWallIosApp.swift          # App entry point
│   ├── Configuration/                      # Environment & app configuration
│   │   └── AppConfiguration.swift         # Environment-based settings
│   ├── Models/                            # Data models
│   │   ├── AuthState.swift                # Authentication state management
│   │   ├── User.swift                     # User & auth response models
│   │   └── Post.swift                     # Post models
│   ├── Networking/                        # Network layer
│   │   ├── NetworkClient.swift            # HTTP client abstraction
│   │   └── NetworkError.swift             # Network error types
│   ├── Protocols/                         # Service protocols
│   │   ├── AuthServiceProtocol.swift      # Authentication service protocol
│   │   └── PostServiceProtocol.swift      # Post service protocol
│   ├── Services/                          # API services
│   │   ├── AuthService.swift              # Authentication API calls
│   │   └── PostService.swift              # Post API calls
│   ├── Views/                             # SwiftUI views
│   │   ├── AuthenticationView.swift       # Landing page
│   │   ├── RegistrationView.swift         # User registration
│   │   ├── LoginView.swift                # User login
│   │   ├── SetPasswordView.swift          # Initial password setup
│   │   ├── ChangePasswordView.swift       # Password change
│   │   ├── ForgotPasswordView.swift       # Password reset
│   │   ├── WallView.swift                 # Main post feed
│   │   ├── CreatePostView.swift           # Create post
│   │   └── PostRowView.swift              # Post list item
│   ├── Utils/                             # Utilities
│   │   ├── KeychainHelper.swift           # Keychain storage
│   │   └── ValidationUtils.swift          # Input validation
│   └── Assets.xcassets/                   # Images & assets
├── AnonymousWallIosTests/                 # Unit tests
└── AnonymousWallIosUITests/               # UI tests
```

## Architecture Layers

### 1. Configuration Layer
**Purpose**: Centralize environment-based configuration

**Components**:
- `AppConfiguration`: Singleton that manages:
  - API base URLs (development, staging, production)
  - Feature flags
  - Logging settings
  - Security configurations
  - UserDefaults keys

**Benefits**:
- Single source of truth for configuration
- Easy switching between environments
- Type-safe configuration access
- No hardcoded values scattered across codebase

### 2. Networking Layer
**Purpose**: Abstract HTTP communication and provide consistent error handling

**Components**:
- `NetworkClient`: Generic HTTP client that:
  - Performs typed requests and responses
  - Handles HTTP status codes
  - Implements request/response logging
  - Provides unified error handling
- `NetworkError`: Standardized error types for network operations

**Benefits**:
- Single place to handle network logic
- Consistent error handling across app
- Easy to mock for testing
- Separation of concerns

### 3. Protocol Layer
**Purpose**: Define service contracts for loose coupling and testability

**Components**:
- `AuthServiceProtocol`: Contract for authentication operations
  - Email verification
  - Registration and login
  - Password management
  - Profile management
- `PostServiceProtocol`: Contract for post operations
  - Post CRUD operations
  - Like/unlike functionality
  - Comment operations
  - User content retrieval

**Benefits**:
- Enables dependency injection and inversion of control
- Allows easy mocking for unit tests
- Decouples high-level modules from concrete implementations
- Facilitates future refactoring and alternative implementations
- Follows SOLID principles (Dependency Inversion Principle)

### 4. Service Layer
**Purpose**: Encapsulate business logic and API communication

**Components**:
- `AuthService`: Authentication operations (conforms to `AuthServiceProtocol`)
  - Email verification
  - Registration
  - Login (password & code)
  - Password management
- `PostService`: Post operations (conforms to `PostServiceProtocol`)
  - Fetch posts
  - Create posts
  - Like/unlike posts
  - Delete posts

**Benefits**:
- Clear separation between UI and API logic
- Reusable across different views
- Easy to test independently
- Single responsibility principle

### 5. Model Layer
**Purpose**: Define data structures and state management

**Components**:
- `User`, `Post`: Data models (Codable)
- `AuthState`: Observable state manager using Combine
- Response models for API calls

**Benefits**:
- Type safety
- Clear data contracts
- Observable state changes
- Consistent data flow

### 6. View Layer
**Purpose**: User interface using SwiftUI

**Components**:
- SwiftUI views for all screens
- Uses `@EnvironmentObject` for shared state
- Reactive UI updates through Combine

**Benefits**:
- Declarative UI
- Automatic updates on state changes
- Clean separation from business logic

### 7. Utils Layer
**Purpose**: Shared utility functions

**Components**:
- `KeychainHelper`: Secure storage wrapper
- `ValidationUtils`: Input validation

**Benefits**:
- Reusable across app
- Centralized common functionality

## Design Patterns

### 1. Singleton Pattern
Used for services and configuration:
- `AppConfiguration.shared`
- `NetworkClient.shared`
- `AuthService.shared`
- `PostService.shared`

**Rationale**: Single instance for shared resources and configuration

### 2. Dependency Injection (Implicit)
Services inject configuration and network client:
```swift
private let config = AppConfiguration.shared
private let networkClient = NetworkClient.shared
```

**Rationale**: Loose coupling, easier testing

### 3. Protocol-Oriented Programming
Services conform to protocols for dependency inversion:
```swift
protocol AuthServiceProtocol {
    func loginWithPassword(email: String, password: String) async throws -> AuthResponse
    // ... other methods
}

class AuthService: AuthServiceProtocol {
    static let shared = AuthService()
    // ... implementation
}
```

**Rationale**: Enables mocking, testability, and follows SOLID principles

### 4. Observable Object Pattern
`AuthState` uses Combine's `@Published` properties:
```swift
class AuthState: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
}
```

**Rationale**: Reactive state management with SwiftUI

### 5. Service Layer Pattern
All API calls go through service classes:
- Views call services
- Services use NetworkClient
- NetworkClient handles HTTP

**Rationale**: Separation of concerns, testability

## Testing Strategy

### Protocol-Based Mocking
The protocol layer enables easy unit testing through mock implementations:

```swift
class MockAuthService: AuthServiceProtocol {
    var loginCalled = false
    
    func loginWithPassword(email: String, password: String) async throws -> AuthResponse {
        loginCalled = true
        return AuthResponse(accessToken: "mock-token", user: mockUser)
    }
}
```

**Benefits**:
- No network calls in unit tests
- Fast and reliable test execution
- Easy verification of service method calls
- Isolated testing of business logic

**Test Coverage**:
- Service protocol conformance tests
- Mock service implementation tests
- Dependency injection pattern demonstrations

## Best Practices Implemented

### ✅ Configuration Management
- ✅ Environment-based configuration
- ✅ No hardcoded URLs or secrets
- ✅ Centralized configuration

### ✅ Error Handling
- ✅ Typed errors
- ✅ Localized error messages
- ✅ Proper error propagation

### ✅ Security
- ✅ Keychain for sensitive data
- ✅ Environment-based HTTPS enforcement
- ✅ Input validation

### ✅ Code Organization
- ✅ Clear folder structure
- ✅ Single responsibility principle
- ✅ Separation of concerns

### ✅ Networking
- ✅ Abstracted network layer
- ✅ Request/response logging (debug only)
- ✅ Proper error handling

### ✅ State Management
- ✅ Observable state with Combine
- ✅ Centralized auth state
- ✅ Persistent session management

## Environment Configuration

### Development (DEBUG)
```swift
AppEnvironment.current = .development
API URL: http://localhost:8080
Logging: Enabled
HTTPS: Not required
```

### Staging
```swift
AppEnvironment.current = .staging
API URL: https://staging-api.anonymouswall.com
Logging: Enabled
HTTPS: Required
```

### Production (RELEASE)
```swift
AppEnvironment.current = .production
API URL: https://api.anonymouswall.com
Logging: Disabled
HTTPS: Required
```

## Data Flow

### Authentication Flow
```
User Input → View → AuthService → NetworkClient → API
                ↓                                    ↓
            AuthState ← ← ← ← ← ← ← ← ← ← ← Response
                ↓
        All Views Update (via @EnvironmentObject)
```

### Post Operations Flow
```
User Input → View → PostService → NetworkClient → API
                ↓                                   ↓
          Local State ← ← ← ← ← ← ← ← ← ← ← Response
                ↓
           View Updates
```

## Future Improvements

### Recommended Enhancements
1. **Dependency Injection Container**
   - Replace singletons with proper DI
   - Enable better testing
   - Consider using a DI framework like Swinject

2. **Repository Pattern**
   - Add caching layer
   - Abstract data sources

3. **Coordinator Pattern**
   - Better navigation management
   - Deep linking support

4. **ViewModels**
   - Extract business logic from Views
   - Use protocol-injected services
   - Enable more comprehensive view testing

5. **SwiftLint Integration**
   - Code style enforcement
   - Best practices checking

6. **Fastlane**
   - Automated builds
   - CI/CD integration

## Comparison: Before vs After

### Before Protocol Layer
❌ Hardcoded service dependencies  
❌ Difficult to test services in isolation  
❌ No dependency inversion  
❌ Tight coupling between views and concrete services  

### After Protocol Layer
✅ Protocol-based service contracts  
✅ Easy mocking for unit tests  
✅ Follows SOLID principles (DIP)  
✅ Loose coupling enables flexibility  
✅ Clear service interfaces documented  

### Original Refactoring
❌ Hardcoded URLs in multiple files  
❌ No network abstraction  
❌ Mixed error types  
❌ Unused template files  
❌ No configuration management  
❌ No `.gitignore`  

✅ Centralized configuration  
✅ Clean network layer  
✅ Standardized errors  
✅ Removed dead code  
✅ Environment-based settings  
✅ Proper `.gitignore`  
✅ Industry-standard structure  

## Contributing

When adding new features:
1. Add new models to `Models/`
2. Add new API calls to appropriate service
3. Use `NetworkClient` for all HTTP requests
4. Access configuration via `AppConfiguration.shared`
5. Store sensitive data in Keychain
6. Follow existing patterns and conventions

## Questions?

See individual file headers for detailed documentation on each component.
