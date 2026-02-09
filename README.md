# AnonymousWallIos

iOS app for college student anonymous posting platform (similar to Blind).

## Features

✅ **Comprehensive Authentication**
- User registration with email and verification code
- Login with email and password
- Login with email and verification code
- Password management (set, change, reset)
- Secure session management with iOS Keychain

✅ **Post Feed**
- Create anonymous posts (max 500 characters)
- View posts from all users
- Like/unlike posts
- Delete own posts
- Pull-to-refresh
- Relative timestamps (e.g., "5m ago", "2h ago")
- Empty state and loading states

## Getting Started

1. Clone the repository
2. Open `AnonymousWallIos.xcodeproj` in Xcode
3. The app is configured to use `http://localhost:8080` in DEBUG mode (for local development)
4. Build and run on iOS Simulator or device

**Environment Configuration:**
- **DEBUG mode**: Uses `http://localhost:8080` for local development
- **RELEASE mode**: Uses production HTTPS URLs (update in `AppConfiguration.swift`)
- API endpoints are centrally managed in `Configuration/AppConfiguration.swift`

**⚠️ Important**: For production deployment, update the production URL in `AppConfiguration.swift` to use your production backend.

## Authentication Flows

### Registration
1. Enter email → Get verification code
2. Enter code → Register
3. Set password (optional, can skip)

### Login
- **With Password**: Email + Password
- **With Code**: Email → Get code → Enter code

### Password Management
- **Set Password**: After registration (optional)
- **Change Password**: When logged in
- **Forgot Password**: Reset via email verification code

## Documentation

- **[API_DOCUMENTATION.md](API_DOCUMENTATION.md)** - Complete API endpoint documentation
- **[POST_FEED_DOCUMENTATION.md](POST_FEED_DOCUMENTATION.md)** - Post feed feature documentation
- **[LOGGER_USAGE.md](LOGGER_USAGE.md)** - Centralized logging usage guide
- **[AUTHENTICATION.md](AUTHENTICATION.md)** - Legacy authentication documentation
- **[UI_DOCUMENTATION.md](UI_DOCUMENTATION.md)** - UI flow and design specifications
- **[UI_SCREENSHOTS.md](UI_SCREENSHOTS.md)** - Visual UI representations
- **[IMPLEMENTATION_SUMMARY.md](IMPLEMENTATION_SUMMARY.md)** - Implementation details
- **[NAVIGATION_IMPROVEMENTS.md](NAVIGATION_IMPROVEMENTS.md)** - Navigation improvements guide

## Requirements

- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+

## Backend Integration

This app requires a backend server with the following endpoints at `http://localhost:8080`:

### Email & Verification
- `POST /api/v1/auth/email/send-code` - Send verification code
- `POST /api/v1/auth/register/email` - Register with code

### Login
- `POST /api/v1/auth/login/email` - Login with verification code
- `POST /api/v1/auth/login/password` - Login with password

### Password Management
- `POST /api/v1/auth/password/set` - Set initial password (requires auth)
- `POST /api/v1/auth/password/change` - Change password (requires auth)
- `POST /api/v1/auth/password/reset-request` - Request password reset
- `POST /api/v1/auth/password/reset` - Reset password with code

### Posts
- `GET /api/v1/posts?page=1&limit=20` - List posts (requires auth)
- `POST /api/v1/posts` - Create new post (requires auth)
- `POST /api/v1/posts/{id}/like` - Like a post (requires auth)
- `DELETE /api/v1/posts/{id}/like` - Unlike a post (requires auth)
- `DELETE /api/v1/posts/{id}` - Delete a post (requires auth)

See [API_DOCUMENTATION.md](API_DOCUMENTATION.md) and [POST_FEED_DOCUMENTATION.md](POST_FEED_DOCUMENTATION.md) for complete API specifications.

## Architecture

The app follows a clean, industry-standard iOS architecture with clear separation of concerns:

### Configuration
- `AppConfiguration` - Environment-based configuration manager
  - Manages API URLs for development, staging, and production
  - Controls feature flags and logging
  - Centralizes security settings and API keys

### Networking
- `NetworkClient` - Network layer abstraction
  - Handles all HTTP communication
  - Implements proper error handling
  - Provides request/response logging for debugging
  - Supports environment-based configuration
- `NetworkError` - Standardized error types for network operations

### Models
- `User` - User data with id, email, verification status
- `AuthState` - Observable authentication state manager
- `AuthResponse` - API response with accessToken and user
- `Post` - Post data with id, content, author, likes

### Services
- `AuthService` - Handles all authentication API calls
  - Uses NetworkClient for API communication
  - Supports environment-based endpoints
- `PostService` - Handles all post-related API calls
  - Uses NetworkClient for API communication
  - Implements proper error handling

### Mocks (for Testing)
- `MockAuthService` - Mock implementation of AuthServiceProtocol
  - Configurable stub responses (success/failure/empty state)
  - Call tracking for test verification
  - No network dependency
- `MockPostService` - Mock implementation of PostServiceProtocol
  - Configurable stub responses (success/failure/empty state)
  - Stateful mock data for realistic testing
  - Call tracking for test verification

### Views
- `AuthenticationView` - Landing page
- `RegistrationView` - Registration with email + code
- `LoginView` - Login (password or code)
- `SetPasswordView` - Initial password setup
- `ChangePasswordView` - Password change
- `ForgotPasswordView` - Password reset
- `WallView` - Main authenticated view with post feed
- `CreatePostView` - Create new anonymous post
- `PostRowView` - Display individual post

### Utils
- `KeychainHelper` - Secure storage for sensitive data
- `ValidationUtils` - Input validation utilities
- `Logger` - Centralized logging infrastructure
  - Structured logging with os.log integration
  - Multiple log levels (Debug, Info, Warning, Error)
  - Environment-aware logging (respects AppConfiguration)
  - Category-based organization (Networking, Authentication, UI, Data, General)
  - Automatic file/function/line context
  - See [LOGGER_USAGE.md](LOGGER_USAGE.md) for detailed usage guide

### Security
- JWT tokens stored in iOS Keychain (encrypted)
- Password validation (min 8 characters)
- Email format validation
- Secure session persistence
- Environment-based HTTPS enforcement
- Centralized configuration management

## Testing

### Running Tests

Run tests in Xcode:
```bash
xcodebuild test -scheme AnonymousWallIos -destination 'platform=iOS Simulator,name=iPhone 15'
```

Or use Xcode's Test Navigator (⌘+6).

### Mock Services

The project includes comprehensive mock implementations for unit testing:

- **`MockAuthService`** - Mock implementation of `AuthServiceProtocol`
  - All 9 authentication methods
  - Configurable success/failure/empty state scenarios
  - Call tracking for test verification
  - Custom response configuration

- **`MockPostService`** - Mock implementation of `PostServiceProtocol`
  - All 12 post/comment/user methods
  - Configurable success/failure/empty state scenarios
  - Stateful mock data (posts, comments)
  - Call tracking for test verification

**Features:**
- ✅ Fast, deterministic tests without network dependency
- ✅ Protocol-based dependency injection
- ✅ Comprehensive test coverage for all scenarios
- ✅ Helper methods for batch configuration

See `AnonymousWallIos/Mocks/README.md` for detailed usage examples and API reference.

**Example:**
```swift
let mockAuth = MockAuthService()
mockAuth.loginWithPasswordBehavior = .failure(MockAuthService.MockError.invalidCredentials)

do {
    _ = try await mockAuth.loginWithPassword(email: "test@test.com", password: "wrong")
    Issue.record("Expected error")
} catch {
    // Verify error handling
}
```

## License

[Add your license here]

