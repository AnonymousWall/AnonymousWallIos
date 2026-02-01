# Quick Start Guide - Anonymous Wall iOS

## Setup

1. **Clone and Open**
   ```bash
   git clone https://github.com/AnonymousWall/AnonymousWallIos.git
   cd AnonymousWallIos
   open AnonymousWallIos.xcodeproj
   ```

2. **Configure Backend URL** (Already set to localhost)
   - File: `AnonymousWallIos/Services/AuthService.swift`
   - Current: `http://localhost:8080`
   - Update for production deployment

3. **Build and Run**
   - Select a simulator (iPhone 15 recommended)
   - Press ⌘R to build and run

## Project Structure

```
AnonymousWallIos/
├── Models/
│   ├── User.swift              # User model + API response models
│   └── AuthState.swift         # Authentication state manager
├── Services/
│   └── AuthService.swift       # All API calls
├── Views/
│   ├── AuthenticationView.swift    # Landing page
│   ├── RegistrationView.swift      # Register with email + code
│   ├── LoginView.swift             # Login (password or code)
│   ├── SetPasswordView.swift       # Set initial password
│   ├── ChangePasswordView.swift    # Change password
│   ├── ForgotPasswordView.swift    # Reset password
│   └── WallView.swift              # Main app (after auth)
└── Utils/
    ├── ValidationUtils.swift   # Email validation
    └── KeychainHelper.swift    # Secure token storage
```

## API Endpoints Summary

Base URL: `http://localhost:8080`

| Method | Endpoint | Purpose | Auth Required |
|--------|----------|---------|---------------|
| POST | `/api/v1/auth/email/send-code` | Send verification code | No |
| POST | `/api/v1/auth/register/email` | Register user | No |
| POST | `/api/v1/auth/login/email` | Login with code | No |
| POST | `/api/v1/auth/login/password` | Login with password | No |
| POST | `/api/v1/auth/password/set` | Set initial password | Yes |
| POST | `/api/v1/auth/password/change` | Change password | Yes |
| POST | `/api/v1/auth/password/reset-request` | Request reset | No |
| POST | `/api/v1/auth/password/reset` | Reset with code | No |

## User Flows

### 1. New User Registration
```
AuthenticationView
  → "Get Started"
    → RegistrationView
      → Enter email → Get Code
      → Enter code → Register
        → Logged in (needsPasswordSetup = true)
          → SetPasswordView (auto-shown)
            → Set password
              → WallView
```

### 2. Login with Password
```
AuthenticationView
  → "Login"
    → LoginView (Password tab)
      → Enter email + password
        → Login
          → WallView
```

### 3. Login with Code
```
AuthenticationView
  → "Login"
    → LoginView (Verification Code tab)
      → Enter email → Get Code
      → Enter code → Login
        → WallView
```

### 4. Forgot Password
```
LoginView
  → "Forgot Password?"
    → ForgotPasswordView
      → Enter email → Send Code
      → Enter code + new password
        → Reset & Login
          → WallView
```

## Key Components

### AuthState (Observable)
```swift
@Published var isAuthenticated: Bool
@Published var currentUser: User?
@Published var authToken: String?
@Published var needsPasswordSetup: Bool
```

### AuthService Methods
```swift
// Registration & Login
sendEmailVerificationCode(email:purpose:) 
registerWithEmail(email:code:)
loginWithEmailCode(email:code:)
loginWithPassword(email:password:)

// Password Management
setPassword(password:token:userId:)
changePassword(oldPassword:newPassword:token:userId:)
requestPasswordReset(email:)
resetPassword(email:code:newPassword:)
```

## Testing

### Run Tests
```bash
xcodebuild test -scheme AnonymousWallIos \
  -destination 'platform=iOS Simulator,name=iPhone 15'
```

### Test Coverage
- ✅ AuthState initialization
- ✅ Login/logout flow
- ✅ User model decoding
- ✅ AuthResponse decoding
- ✅ Email validation
- ✅ Keychain operations
- ✅ Password setup status

## Development Tips

### 1. Testing with Local Backend
```bash
# Start your backend on localhost:8080
# The app is already configured for this
```

### 2. Debugging API Calls
Enable network logging in `AuthService.swift`:
```swift
print("Request: \(request.url?.absoluteString ?? "")")
print("Response: \(String(data: data, encoding: .utf8) ?? "")")
```

### 3. Reset App State
Clear authentication:
```swift
authState.logout()  // Clears Keychain and UserDefaults
```

### 4. Common Issues

**Problem**: "Network error"
- Solution: Check if backend is running on localhost:8080

**Problem**: "Decoding error"
- Solution: Check API response format matches model

**Problem**: Password setup not showing
- Solution: Check `needsPasswordSetup` flag in `AuthState`

## Security Notes

✅ **Secure Storage**
- JWT tokens in iOS Keychain (encrypted)
- Keychain items: `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`

✅ **Validation**
- Email format validated client-side
- Password minimum 8 characters
- Passwords match confirmation

✅ **Session Management**
- Token automatically included in authenticated requests
- Session cleared completely on logout

## Next Steps for Production

- [ ] Update base URL to production server
- [ ] Add proper error tracking/analytics
- [ ] Implement token refresh mechanism
- [ ] Add biometric authentication (Face ID/Touch ID)
- [ ] Add app icon and launch screen
- [ ] Configure proper code signing
- [ ] Test on physical devices
- [ ] Submit to App Store

## Support

For backend API specifications, see:
- **API_DOCUMENTATION.md** - Complete endpoint documentation
- **AUTHENTICATION.md** - Legacy documentation
- **README.md** - Project overview

## Quick Commands

```bash
# Clean build
xcodebuild clean -scheme AnonymousWallIos

# Build
xcodebuild build -scheme AnonymousWallIos

# Run tests
xcodebuild test -scheme AnonymousWallIos -destination 'platform=iOS Simulator,name=iPhone 15'

# Archive for distribution
xcodebuild archive -scheme AnonymousWallIos -archivePath ./build/AnonymousWallIos.xcarchive
```
