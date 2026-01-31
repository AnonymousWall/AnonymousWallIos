# AnonymousWallIos

iOS app for college student anonymous posting platform (similar to Blind).

## Features

✅ **Email-based Authentication**
- User registration with email
- Login with email and verification code
- Secure session management

## Getting Started

1. Clone the repository
2. Open `AnonymousWallIos.xcodeproj` in Xcode
3. Update the backend URL in `AnonymousWallIos/Services/AuthService.swift`
4. Build and run on iOS Simulator or device

## Documentation

See [AUTHENTICATION.md](AUTHENTICATION.md) for detailed documentation on the authentication system and backend API requirements.

## Requirements

- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+

## Backend Integration

This app requires a backend server with the following endpoints:
- `POST /auth/register` - Register new user and send verification code
- `POST /auth/login` - Login with email and verification code
- `POST /auth/request-code` - Request new verification code

See [AUTHENTICATION.md](AUTHENTICATION.md) for complete API specifications.
