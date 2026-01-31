# Anonymous Wall iOS - Authentication

## Overview

This iOS app implements email-based authentication with verification codes for a college student anonymous posting platform.

## Features

- **Email Registration**: Users can register with their email address
- **Verification Code Login**: Users receive a verification code via email to log in
- **Session Management**: User sessions are persisted across app launches
- **Clean UI**: SwiftUI-based interface with modern design

## Architecture

### Models (`Models/`)

- **User.swift**: User data model
  - `User`: Represents an authenticated user with id, email, and creation date
  - `AuthResponse`: Response model for authentication API calls
  - `VerificationCodeResponse`: Response model for verification code requests

- **AuthState.swift**: Authentication state management
  - `AuthState`: ObservableObject that manages authentication state across the app
  - Handles login, logout, and session persistence using UserDefaults

### Services (`Services/`)

- **AuthService.swift**: Network service for authentication
  - `register(email:)`: Sends verification code to email for new users
  - `login(email:verificationCode:)`: Authenticates user with email and verification code
  - `requestVerificationCode(email:)`: Requests a new verification code for existing users

### Views (`Views/`)

- **AuthenticationView.swift**: Landing page with options to register or login
- **RegistrationView.swift**: Email registration form
- **LoginView.swift**: Login form with email and verification code inputs
- **WallView.swift**: Main authenticated view (placeholder for post feed)

## Backend API Integration

The app expects the following API endpoints from the backend:

### 1. Register New User
```
POST /auth/register
Content-Type: application/json

Request Body:
{
  "email": "user@example.com"
}

Response:
{
  "success": true,
  "message": "Verification code sent to your email"
}
```

### 2. Login with Verification Code
```
POST /auth/login
Content-Type: application/json

Request Body:
{
  "email": "user@example.com",
  "verification_code": "123456"
}

Response:
{
  "success": true,
  "message": "Login successful",
  "user": {
    "id": "user-id",
    "email": "user@example.com",
    "created_at": "2026-01-31T00:00:00Z"
  },
  "token": "jwt-token-here"
}
```

### 3. Request Verification Code
```
POST /auth/request-code
Content-Type: application/json

Request Body:
{
  "email": "user@example.com"
}

Response:
{
  "success": true,
  "message": "Verification code sent to your email"
}
```

## Configuration

⚠️ **Important**: Update the backend URL in `Services/AuthService.swift`:

```swift
private let baseURL = "https://api.example.com" // Replace with your actual backend URL
```

## User Flow

1. **First Time Users**:
   - Open app → See AuthenticationView
   - Tap "Get Started" → RegistrationView
   - Enter email → Receive verification code via email
   - Navigate to LoginView
   - Enter email and verification code → Login successful

2. **Returning Users**:
   - Open app → See AuthenticationView
   - Tap "Login" → LoginView
   - Tap "Get Code" to request new verification code
   - Enter verification code → Login successful

3. **Authenticated Users**:
   - App opens directly to WallView
   - Can logout to return to AuthenticationView

## Session Persistence

User sessions are stored in UserDefaults with the following keys:
- `isAuthenticated`: Boolean indicating authentication status
- `authToken`: JWT token for API requests
- `userId`: User's unique identifier
- `userEmail`: User's email address

## Security Notes

- All API calls use HTTPS (ensure your backend URL uses https://)
- JWT tokens are stored securely in UserDefaults
- Verification codes should be time-limited on the backend
- Email validation is performed client-side before API calls

## Testing

The app includes basic test infrastructure:
- Unit tests can be added in `AnonymousWallIosTests/`
- UI tests can be added in `AnonymousWallIosUITests/`

## Next Steps

To complete the implementation:
1. Update `baseURL` in `AuthService.swift` with your backend URL
2. Implement the post feed in `WallView.swift`
3. Add error handling and retry logic
4. Implement token refresh mechanism
5. Add unit tests for authentication logic
6. Add UI tests for authentication flows
