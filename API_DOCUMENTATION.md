# Anonymous Wall iOS - Authentication API Documentation

## Overview

This iOS app implements comprehensive email-based authentication with verification codes and password management for a college student anonymous posting platform.

## Base URL

```
http://localhost:8080
```

## Features

- **Email Registration**: Register with email and verification code
- **Email + Code Login**: Login with email and verification code
- **Email + Password Login**: Login with email and password
- **Password Management**: Set, change, and reset passwords
- **Session Management**: Secure token storage in iOS Keychain
- **Modern UI**: SwiftUI-based interface with clean design

## Architecture

### Models (`Models/`)

- **User.swift**: User data model
  - `User`: Represents an authenticated user with id, email, verification status, and creation date
  - `AuthResponse`: Response model for authentication API calls (accessToken + user)
  - `VerificationCodeResponse`: Response model for verification code operations
  - `ErrorResponse`: Error response model

- **AuthState.swift**: Authentication state management
  - `AuthState`: ObservableObject that manages authentication state across the app
  - Handles login, logout, password setup status, and session persistence
  - Uses Keychain for secure token storage and UserDefaults for non-sensitive data

### Services (`Services/`)

- **AuthService.swift**: Network service for all authentication operations
  - Email verification code operations
  - Registration and login (both methods)
  - Password management (set, change, reset)

### Views (`Views/`)

- **AuthenticationView.swift**: Landing page with register/login options
- **RegistrationView.swift**: Email registration with verification code
- **LoginView.swift**: Login with email + password or email + code
- **SetPasswordView.swift**: Initial password setup after registration
- **ChangePasswordView.swift**: Change password when logged in
- **ForgotPasswordView.swift**: Password reset flow
- **WallView.swift**: Main authenticated view with password setup prompt

### Utils (`Utils/`)

- **ValidationUtils.swift**: Email validation utilities
- **KeychainHelper.swift**: Secure storage for JWT tokens

## API Endpoints

### 1. Send Email Verification Code (for Registration)

```http
POST /api/v1/auth/email/send-code
Content-Type: application/json

Request:
{
  "email": "student@nyu.edu",
  "purpose": "register"
}

Response: 200 OK
(String or JSON with message)
```

### 2. Register with Email and Verification Code

```http
POST /api/v1/auth/register/email
Content-Type: application/json

Request:
{
  "email": "student@nyu.edu",
  "code": "123456"
}

Response: 200 OK
{
  "accessToken": "eyJhbGc...",
  "user": {
    "id": "uuid",
    "email": "student@nyu.edu",
    "isVerified": true,
    "createdAt": "2026-01-30T15:17:41-08:00[America/Los_Angeles]"
  }
}
```

**Note**: After registration, user is logged in but needs to set a password.

### 3. Send Email Verification Code (for Login)

```http
POST /api/v1/auth/email/send-code
Content-Type: application/json

Request:
{
  "email": "student@nyu.edu",
  "purpose": "login"
}

Response: 200 OK
(String or JSON with message)
```

### 4. Login with Email and Verification Code

```http
POST /api/v1/auth/login/email
Content-Type: application/json

Request:
{
  "email": "student@nyu.edu",
  "code": "034883"
}

Response: 200 OK
{
  "accessToken": "eyJhbGc...",
  "user": {
    "id": "uuid",
    "email": "student@nyu.edu",
    "isVerified": true,
    "createdAt": "2026-01-30T15:17:41-08:00[America/Los_Angeles]"
  }
}
```

### 5. Set Initial Password (After Registration)

```http
POST /api/v1/auth/password/set
Content-Type: application/json
Authorization: Bearer {accessToken}
X-User-ID: {userId}

Request:
{
  "password": "mySecurePassword123"
}

Response: 200 OK
(Success message)
```

**Note**: This endpoint requires authentication (Bearer token) and user ID header.

### 6. Login with Email and Password

```http
POST /api/v1/auth/login/password
Content-Type: application/json

Request:
{
  "email": "student@mit.edu",
  "password": "mySecurePassword123"
}

Response: 200 OK
{
  "accessToken": "eyJhbGc...",
  "user": {
    "id": "uuid",
    "email": "student@mit.edu",
    "isVerified": true,
    "createdAt": "2026-01-30T15:17:41-08:00[America/Los_Angeles]"
  }
}
```

### 7. Change Password (When Logged In)

```http
POST /api/v1/auth/password/change
Content-Type: application/json
Authorization: Bearer {accessToken}
X-User-ID: {userId}

Request:
{
  "oldPassword": "mySecurePassword123",
  "newPassword": "myNewPassword456"
}

Response: 200 OK
(Success message)
```

**Note**: Requires authentication and user ID header.

### 8. Request Password Reset

```http
POST /api/v1/auth/password/reset-request
Content-Type: application/json

Request:
{
  "email": "student@mit.edu"
}

Response: 200 OK
(Success message)
```

### 9. Reset Password with Verification Code

```http
POST /api/v1/auth/password/reset
Content-Type: application/json

Request:
{
  "email": "student@mit.edu",
  "code": "364752",
  "newPassword": "myNewPassword789"
}

Response: 200 OK
{
  "accessToken": "eyJhbGc...",
  "user": {
    "id": "uuid",
    "email": "student@mit.edu",
    "isVerified": true,
    "createdAt": "2026-01-30T15:17:41-08:00[America/Los_Angeles]"
  }
}
```

**Note**: User is automatically logged in after successful password reset.

## User Flows

### Registration Flow

1. User enters email on RegistrationView
2. Clicks "Get Code" → API: `/api/v1/auth/email/send-code` (purpose: register)
3. Enters verification code
4. Clicks "Register" → API: `/api/v1/auth/register/email`
5. User is logged in (with `needsPasswordSetup = true`)
6. SetPasswordView appears prompting to set password
7. User sets password → API: `/api/v1/auth/password/set`
8. User can now use WallView

### Login Flow (with Password)

1. User selects "Password" tab on LoginView
2. Enters email and password
3. Clicks "Login" → API: `/api/v1/auth/login/password`
4. User is logged in and sees WallView

### Login Flow (with Verification Code)

1. User selects "Verification Code" tab on LoginView
2. Enters email and clicks "Get Code" → API: `/api/v1/auth/email/send-code` (purpose: login)
3. Enters verification code
4. Clicks "Login" → API: `/api/v1/auth/login/email`
5. User is logged in and sees WallView

### Forgot Password Flow

1. User clicks "Forgot Password?" on LoginView
2. ForgotPasswordView opens
3. Enters email and clicks "Send Code" → API: `/api/v1/auth/password/reset-request`
4. Enters verification code and new password
5. Clicks "Reset Password" → API: `/api/v1/auth/password/reset`
6. User is logged in with new password

### Change Password Flow

1. Logged-in user clicks "Change Password" on WallView
2. ChangePasswordView opens
3. Enters old password, new password, and confirmation
4. Clicks "Change Password" → API: `/api/v1/auth/password/change`
5. Password is updated

## Security

- **JWT Tokens**: Stored securely in iOS Keychain with `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`
- **Password Requirements**: Minimum 8 characters
- **Non-Sensitive Data**: User ID, email, verification status stored in UserDefaults
- **HTTPS**: All API calls use HTTP (localhost for development)
- **Validation**: Client-side email validation before API calls
- **Session Cleanup**: All authentication data cleared on logout

## Session Persistence

**Keychain** (secure, encrypted):
- `com.anonymouswall.authToken`: JWT access token

**UserDefaults** (non-sensitive):
- `isAuthenticated`: Boolean
- `userId`: User's unique ID
- `userEmail`: User's email
- `userIsVerified`: Verification status
- `needsPasswordSetup`: Whether password needs to be set

## Configuration

The base URL is configured in `AuthService.swift`:

```swift
private let baseURL = "http://localhost:8080"
```

Update this to your backend server URL before deployment.

## Error Handling

All API errors are handled with the `AuthError` enum:

- `.invalidURL`: Malformed URL
- `.invalidResponse`: Non-HTTP response or invalid status
- `.networkError(Error)`: Network connectivity issues
- `.serverError(String)`: Backend error with message
- `.decodingError`: JSON parsing failure
- `.unauthorized`: 401 status (session expired)

Errors are displayed to users in red text below input fields.

## Testing

Run unit tests:
```bash
xcodebuild test -scheme AnonymousWallIos -destination 'platform=iOS Simulator,name=iPhone 15'
```

Tests cover:
- AuthState login/logout
- User model decoding
- AuthResponse decoding
- Email validation
- Keychain operations
- Password setup status

## Next Steps

1. ✅ Update base URL to production server
2. ✅ Test all authentication flows
3. Implement post feed functionality
4. Add token refresh mechanism
5. Add biometric authentication (Face ID/Touch ID)
6. Add rate limiting UI feedback
7. Implement analytics for auth events
