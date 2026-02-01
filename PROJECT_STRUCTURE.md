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

### 3. Service Layer
**Purpose**: Encapsulate business logic and API communication

**Components**:
- `AuthService`: Authentication operations
  - Email verification
  - Registration
  - Login (password & code)
  - Password management
- `PostService`: Post operations
  - Fetch posts
  - Create posts
  - Like/unlike posts
  - Delete posts

**Benefits**:
- Clear separation between UI and API logic
- Reusable across different views
- Easy to test independently
- Single responsibility principle

### 4. Model Layer
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

### 5. View Layer
**Purpose**: User interface using SwiftUI

**Components**:
- SwiftUI views for all screens
- Uses `@EnvironmentObject` for shared state
- Reactive UI updates through Combine

**Benefits**:
- Declarative UI
- Automatic updates on state changes
- Clean separation from business logic

### 6. Utils Layer
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

### 3. Observable Object Pattern
`AuthState` uses Combine's `@Published` properties:
```swift
class AuthState: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
}
```

**Rationale**: Reactive state management with SwiftUI

### 4. Service Layer Pattern
All API calls go through service classes:
- Views call services
- Services use NetworkClient
- NetworkClient handles HTTP

**Rationale**: Separation of concerns, testability

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

2. **Repository Pattern**
   - Add caching layer
   - Abstract data sources

3. **Coordinator Pattern**
   - Better navigation management
   - Deep linking support

4. **Unit Tests**
   - Service layer tests
   - Network layer tests
   - ViewModel tests

5. **SwiftLint Integration**
   - Code style enforcement
   - Best practices checking

6. **Fastlane**
   - Automated builds
   - CI/CD integration

## Comparison: Before vs After

### Before Refactoring
❌ Hardcoded URLs in multiple files  
❌ No network abstraction  
❌ Mixed error types  
❌ Unused template files  
❌ No configuration management  
❌ No `.gitignore`  

### After Refactoring
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
