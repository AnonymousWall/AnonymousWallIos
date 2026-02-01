# Anonymous Wall iOS - API Documentation

## Overview

This iOS app implements comprehensive email-based authentication with verification codes, password management, and anonymous posting features for a college student platform with campus and national walls.

## Base URL

```
http://localhost:8080
```

## Features

- **Email Registration**: Register with email and verification code
- **Email + Code Login**: Login with email and verification code
- **Email + Password Login**: Login with email and password
- **Password Management**: Set, change, and reset passwords
- **Anonymous Posting**: Create anonymous posts on campus or national walls
- **Post Interactions**: Like/unlike posts and add comments
- **Session Management**: Secure token storage in iOS Keychain
- **Modern UI**: SwiftUI-based interface with clean design

## Architecture

### Models (`Models/`)

- **User.swift**: User data model
  - `User`: Represents an authenticated user with id, email, verification status, password setup status, and creation date
  - `AuthResponse`: Response model for authentication API calls (user + accessToken)
  - `VerificationCodeResponse`: Response model for verification code operations
  - `ErrorResponse`: Error response model

- **Post.swift**: Post and comment data models
  - `Post`: Represents an anonymous post with content, wall type, likes, comments, author info, and timestamps
  - `PostListResponse`: Paginated list of posts with metadata
  - `Comment`: Represents a comment on a post
  - `CommentListResponse`: Paginated list of comments
  - `CreatePostRequest`: Request model for creating a post
  - `LikeResponse`: Response model for like/unlike operations

- **AuthState.swift**: Authentication state management
  - `AuthState`: ObservableObject that manages authentication state across the app
  - Handles login, logout, password setup status, and session persistence
  - Uses Keychain for secure token storage and UserDefaults for non-sensitive data

### Services (`Services/`)

- **AuthService.swift**: Network service for all authentication operations
  - Email verification code operations
  - Registration and login (both methods)
  - Password management (set, change, reset)

- **PostService.swift**: Network service for post operations
  - Fetch posts with filtering and pagination
  - Create posts on campus or national walls
  - Toggle likes on posts
  - Add and fetch comments

### Views (`Views/`)

- **AuthenticationView.swift**: Landing page with register/login options
- **RegistrationView.swift**: Email registration with verification code
- **LoginView.swift**: Login with email + password or email + code
- **SetPasswordView.swift**: Initial password setup after registration
- **ChangePasswordView.swift**: Change password when logged in
- **ForgotPasswordView.swift**: Password reset flow
- **WallView.swift**: Main authenticated view displaying posts
- **CreatePostView.swift**: Create new posts with wall selection
- **PostRowView.swift**: Individual post display component

### Utils (`Utils/`)

- **ValidationUtils.swift**: Email validation utilities
- **KeychainHelper.swift**: Secure storage for JWT tokens

## API Endpoints

### Authentication Endpoints

#### 1. Send Email Verification Code

```http
POST /api/v1/auth/email/send-code
Content-Type: application/json

Request:
{
  "email": "student@harvard.edu",
  "purpose": "register"  // or "login", "reset_password"
}

Response: 200 OK
{
  "message": "Verification code sent to email"
}
```

#### 2. Register with Email Code

```http
POST /api/v1/auth/register/email
Content-Type: application/json

Request:
{
  "email": "student@harvard.edu",
  "code": "123456"
}

Response: 201 Created
{
  "user": {
    "id": "uuid",
    "email": "student@harvard.edu",
    "isVerified": true,
    "passwordSet": false,
    "createdAt": "2026-01-28T..."
  },
  "accessToken": "jwt-token-here"
}
```

**Note**: After registration, user is logged in but needs to set a password.

#### 3. Login with Email Code

```http
POST /api/v1/auth/login/email
Content-Type: application/json

Request:
{
  "email": "student@harvard.edu",
  "code": "123456"
}

Response: 200 OK
{
  "user": {...},
  "accessToken": "jwt-token-here"
}
```

#### 4. Login with Password

```http
POST /api/v1/auth/login/password
Content-Type: application/json

Request:
{
  "email": "student@harvard.edu",
  "password": "secure_password"
}

Response: 200 OK
{
  "user": {...},
  "accessToken": "jwt-token-here"
}
```

#### 5. Set Password (Requires Authentication)

```http
POST /api/v1/auth/password/set
Header: X-User-Id: {userId}
Authorization: Bearer {jwt-token}
Content-Type: application/json

Request:
{
  "password": "secure_password"
}

Response: 200 OK
{
  "id": "uuid",
  "email": "student@harvard.edu",
  "isVerified": true,
  "passwordSet": true,
  "createdAt": "2026-01-28T..."
}
```

#### 6. Change Password (Requires Authentication)

```http
POST /api/v1/auth/password/change
Header: X-User-Id: {userId}
Authorization: Bearer {jwt-token}
Content-Type: application/json

Request:
{
  "oldPassword": "current_password",
  "newPassword": "new_password"
}

Response: 200 OK
{
  "id": "uuid",
  "email": "student@harvard.edu",
  "isVerified": true,
  "passwordSet": true,
  "createdAt": "2026-01-28T..."
}
```

#### 7. Reset Password Request

```http
POST /api/v1/auth/password/reset-request
Content-Type: application/json

Request:
{
  "email": "student@harvard.edu"
}

Response: 200 OK
{
  "message": "Password reset code sent to email"
}
```

#### 8. Reset Password with Verification Code

```http
POST /api/v1/auth/password/reset
Content-Type: application/json

Request:
{
  "email": "student@nyu.edu",
  "code": "339124",
  "newPassword": "myNewPassword789"
}

Response: 200 OK
{
  "accessToken": "eyJhbGc...",
  "user": {
    "id": "uuid",
    "email": "student@nyu.edu",
    "isVerified": true,
    "createdAt": "2026-01-30T..."
  }
}
```

**Note**: User is automatically logged in after successful password reset.

### Post Endpoints

#### 1. Create Post

```http
POST /api/v1/posts
Authorization: Bearer {jwt-token}
Content-Type: application/json

Request:
{
  "content": "This is my first post!",
  "wall": "campus"  // or "national"
}

Response: 201 Created
{
  "id": "1",
  "content": "This is my first post!",
  "wall": "CAMPUS",
  "likes": 0,
  "comments": 0,
  "liked": false,
  "author": {
    "id": "uuid",
    "isAnonymous": true
  },
  "createdAt": "2026-01-28T...",
  "updatedAt": "2026-01-28T..."
}
```

#### 2. List Posts

```http
GET /api/v1/posts?wall=campus&page=1&limit=20&sort=NEWEST
Authorization: Bearer {jwt-token}

Response: 200 OK
{
  "data": [
    {
      "id": "1",
      "content": "Post content",
      "wall": "CAMPUS",
      "likes": 5,
      "comments": 2,
      "liked": false,
      "author": {
        "id": "uuid",
        "isAnonymous": true
      },
      "createdAt": "2026-01-28T...",
      "updatedAt": "2026-01-28T..."
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 150,
    "totalPages": 8
  }
}
```

**Query Parameters:**
- `wall` (default: "campus") - Filter by "campus" or "national"
- `page` (default: 1) - Page number (1-based)
- `limit` (default: 20) - Posts per page (max: 100)
- `sort` (default: "NEWEST") - Sort order: NEWEST, OLDEST, MOST_LIKED, LEAST_LIKED

#### 3. Toggle Like on Post

```http
POST /api/v1/posts/{postId}/likes
Authorization: Bearer {jwt-token}

Response: 200 OK
{
  "liked": true  // or false if unlike
}
```

#### 4. Add Comment

```http
POST /api/v1/posts/{postId}/comments
Authorization: Bearer {jwt-token}
Content-Type: application/json

Request:
{
  "text": "Great post!"
}

Response: 201 Created
{
  "id": "1",
  "postId": "1",
  "text": "Great post!",
  "author": {
    "id": "uuid",
    "isAnonymous": true
  },
  "createdAt": "2026-01-28T..."
}
```

#### 5. Get Comments for Post

```http
GET /api/v1/posts/{postId}/comments?page=1&limit=20&sort=NEWEST
Authorization: Bearer {jwt-token}

Response: 200 OK
{
  "data": [
    {
      "id": "1",
      "postId": "1",
      "text": "Great post!",
      "author": {
        "id": "uuid",
        "isAnonymous": true
      },
      "createdAt": "2026-01-28T..."
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 5,
    "totalPages": 1
  }
}
```

**Query Parameters:**
- `page` (default: 1) - Page number (1-based)
- `limit` (default: 20) - Comments per page (max: 100)
- `sort` (default: "NEWEST") - Sort order: NEWEST, OLDEST

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

The base URL is configured in `AppConfiguration.swift`:

```swift
var apiBaseURL: String {
    switch environment {
    case .development:
        return "http://localhost:8080"
    case .staging:
        return "https://staging-api.anonymouswall.com"
    case .production:
        return "https://api.anonymouswall.com"
    }
}
```

Update this to your backend server URL before deployment.

## Error Handling

All API errors are handled with the `NetworkError` enum:

- `.invalidURL`: Malformed URL
- `.invalidResponse`: Non-HTTP response or invalid status
- `.networkError(Error)`: Network connectivity issues
- `.serverError(String)`: Backend error with message
- `.decodingError`: JSON parsing failure
- `.unauthorized`: 401 status (session expired)
- `.forbidden`: 403 status (access denied)
- `.notFound`: 404 status (resource not found)
- `.timeout`: 408 status (request timeout)
- `.noConnection`: No internet connection

Errors are displayed to users in red text below input fields.

## HTTP Status Codes

- `200 OK` - Success
- `201 Created` - Resource created
- `400 Bad Request` - Invalid input
- `401 Unauthorized` - Missing/invalid JWT token
- `403 Forbidden` - User doesn't have access (wrong school domain)
- `404 Not Found` - Resource not found
- `409 Conflict` - Resource already exists (email already registered)
- `500 Internal Server Error` - Server error

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

## Implementation Notes

### API Changes from Initial Spec

The following changes were made to align with the backend API specification:

1. **User Model**: Added `passwordSet` field to track password setup status
2. **Post Model**: Updated to include `wall`, `likes`, `comments`, `liked`, `author` structure, and `updatedAt`
3. **Post Creation**: Added `wall` parameter to specify campus or national posting
4. **Post Listing**: Added support for `wall`, `page`, `limit`, and `sort` query parameters
5. **Like System**: Changed from separate like/unlike endpoints to a single toggle endpoint at `/posts/{id}/likes`
6. **Comments**: Added full comment support with create and list endpoints
7. **Headers**: Standardized on `X-User-Id` header name (case-sensitive)
8. **Delete Posts**: Removed delete functionality as it's not supported by the backend API

### Known Limitations

- Delete post functionality is not available in the current backend API
- Posts are fully anonymous - no way to identify the author except comparing with current user ID
- No edit functionality for posts or comments
- No notification system for likes or comments

## Next Steps

1. ✅ Update models to match backend specification
2. ✅ Update services to match backend endpoints
3. ✅ Update views to support new features (wall selection, comments)
4. Implement comment viewing UI
5. Add pull-to-refresh for post feed
6. Add token refresh mechanism
7. Add biometric authentication (Face ID/Touch ID)
8. Add rate limiting UI feedback
9. Implement analytics for user events
