# AnonymousWallIos

iOS app for college student anonymous posting platform (similar to Blind).

## Features

✅ **Comprehensive Authentication**
- User registration with email and verification code
- Login with email and password
- Login with email and verification code
- Password management (set, change, reset)
- Secure session management with iOS Keychain

## Getting Started

1. Clone the repository
2. Open `AnonymousWallIos.xcodeproj` in Xcode
3. The app is configured to use `http://localhost:8080` as the base URL (for local development)
4. Build and run on iOS Simulator or device

**⚠️ Important**: For production deployment, update the base URL in `AuthService.swift` to use HTTPS to protect authentication tokens in transit.

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
- **[AUTHENTICATION.md](AUTHENTICATION.md)** - Legacy authentication documentation
- **[UI_DOCUMENTATION.md](UI_DOCUMENTATION.md)** - UI flow and design specifications
- **[UI_SCREENSHOTS.md](UI_SCREENSHOTS.md)** - Visual UI representations
- **[IMPLEMENTATION_SUMMARY.md](IMPLEMENTATION_SUMMARY.md)** - Implementation details

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

See [API_DOCUMENTATION.md](API_DOCUMENTATION.md) for complete API specifications.

## Architecture

### Models
- `User` - User data with id, email, verification status
- `AuthState` - Observable authentication state manager
- `AuthResponse` - API response with accessToken and user

### Services
- `AuthService` - Handles all authentication API calls

### Views
- `AuthenticationView` - Landing page
- `RegistrationView` - Registration with email + code
- `LoginView` - Login (password or code)
- `SetPasswordView` - Initial password setup
- `ChangePasswordView` - Password change
- `ForgotPasswordView` - Password reset
- `WallView` - Main authenticated view

### Security
- JWT tokens stored in iOS Keychain (encrypted)
- Password validation (min 8 characters)
- Email format validation
- Secure session persistence

## Testing

Run tests:
```bash
xcodebuild test -scheme AnonymousWallIos -destination 'platform=iOS Simulator,name=iPhone 15'
```

## License

[Add your license here]

