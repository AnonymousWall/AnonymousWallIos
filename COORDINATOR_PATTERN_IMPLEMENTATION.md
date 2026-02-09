# Coordinator Pattern Implementation

## Overview

This document describes the implementation of the Coordinator Pattern for navigation management in the AnonymousWallIos app.

## Problem Statement

Previously, the app had navigation logic tightly coupled with views:
- Views directly created `NavigationLink`s to other views
- Navigation state was scattered across multiple views
- Hard to test navigation logic independently
- Difficult to manage programmatic navigation or deep linking
- No central place to control navigation flow

## Solution: Coordinator Pattern

The Coordinator Pattern centralizes all navigation logic, allowing views to focus on presentation while coordinators handle navigation decisions.

### Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        AppCoordinator                       │
│  (Main coordinator managing app-level navigation)           │
│                                                              │
│  ┌──────────────────┐      ┌──────────────────┐           │
│  │  AuthCoordinator │      │  TabCoordinator  │           │
│  │  (Auth flow)     │      │  (Main app tabs) │           │
│  └──────────────────┘      └──────────────────┘           │
│                                      │                      │
│                    ┌────────────────┼──────────────┐      │
│                    ▼                ▼              ▼       │
│           ┌────────────┐   ┌──────────────┐  ┌──────────┐│
│           │HomeCoord.  │   │CampusCoord.  │  │ProfileC..││
│           │(Home nav)  │   │(Campus nav)  │  │(Profile) ││
│           └────────────┘   └──────────────┘  └──────────┘│
└─────────────────────────────────────────────────────────────┘
```

## Core Components

### 1. Coordinator Protocol

```swift
protocol Coordinator: AnyObject, ObservableObject {
    associatedtype Destination: Hashable
    
    var path: NavigationPath { get set }
    
    func navigate(to destination: Destination)
    func popToRoot()
    func pop()
}
```

**Features:**
- Generic `Destination` type for type-safe navigation
- `NavigationPath` for managing navigation stack
- Default implementations for common operations

### 2. AppCoordinator

The root coordinator that manages high-level app navigation:
- Owns `AuthCoordinator` for authentication flow
- Owns `TabCoordinator` for main app navigation
- Initialized with `AuthState` for authentication-based routing

### 3. AuthCoordinator

Manages authentication-related navigation:
- **Destinations:** `.login`, `.registration`, `.forgotPassword`
- Controls navigation between login, registration, and password recovery
- Manages sheet presentations for modal flows

### 4. TabCoordinator

Manages tab-based navigation and child coordinators:
- Owns coordinators for each main tab (Home, Campus, Profile)
- Manages tab selection state
- Provides child coordinators to respective views

### 5. Feature Coordinators

Each main feature has its own coordinator:

**HomeCoordinator:**
- Handles national feed navigation
- Destinations: `.postDetail(Post)`, `.setPassword`

**CampusCoordinator:**
- Handles campus feed navigation
- Destinations: `.postDetail(Post)`, `.setPassword`

**ProfileCoordinator:**
- Handles profile navigation
- Destinations: `.postDetail(Post)`, `.setPassword`, `.changePassword`, `.editProfileName`

## Navigation Flow

### Authentication Flow

```
AuthenticationView (uses AuthCoordinator)
    │
    ├─> Navigate to .registration
    │       └─> RegistrationView
    │           └─> Navigate to .login
    │               └─> LoginView
    │
    └─> Navigate to .login
        └─> LoginView
            └─> Navigate to .forgotPassword (sheet)
                └─> ForgotPasswordView
```

### Main App Flow

```
TabBarView (uses TabCoordinator)
    │
    ├─> Tab 0: HomeView (uses HomeCoordinator)
    │       └─> Navigate to .postDetail(post)
    │           └─> PostDetailView
    │
    ├─> Tab 1: CampusView (uses CampusCoordinator)
    │       └─> Navigate to .postDetail(post)
    │           └─> PostDetailView
    │
    └─> Tab 3: ProfileView (uses ProfileCoordinator)
        ├─> Navigate to .postDetail(post)
        │   └─> PostDetailView
        ├─> Navigate to .editProfileName (sheet)
        │   └─> EditProfileNameView
        └─> Navigate to .changePassword (sheet)
            └─> ChangePasswordView
```

## Key Changes

### Before (Direct NavigationLink)

```swift
NavigationLink(destination: PostDetailView(post: post)) {
    PostRowView(post: post)
}
```

### After (Coordinator-based)

```swift
Button {
    coordinator.navigate(to: .postDetail(post))
} label: {
    PostRowView(post: post)
}

// In NavigationStack
.navigationDestination(for: HomeCoordinator.Destination.self) { destination in
    switch destination {
    case .postDetail(let post):
        PostDetailView(post: .constant(post))
    case .setPassword:
        EmptyView() // Handled as sheet
    }
}
```

## Benefits

✅ **Separation of Concerns**
- Views focus on presentation
- Coordinators handle navigation logic
- Clear separation between UI and flow control

✅ **Testability**
- Navigation logic can be tested independently
- Mock coordinators can be injected for testing
- Views are easier to test in isolation

✅ **Maintainability**
- All navigation logic in one place
- Easy to understand and modify navigation flows
- Less deeply nested code

✅ **Flexibility**
- Easy to add new navigation paths
- Programmatic navigation is straightforward
- Deep linking support can be added easily

✅ **Type Safety**
- Compile-time checking for navigation destinations
- Enum-based destinations prevent typos

## Implementation Details

### Post Model Changes

Added `Hashable` conformance to `Post` model:

```swift
struct Post: Codable, Identifiable, Hashable {
    // ... existing properties ...
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Post, rhs: Post) -> Bool {
        lhs.id == rhs.id
    }
}
```

This enables `Post` to be used in coordinator destinations.

### View Refactoring Pattern

Each view was refactored to:
1. Accept a coordinator as a parameter
2. Use `NavigationStack(path: $coordinator.path)` instead of plain `NavigationStack`
3. Replace `NavigationLink`s with `Button`s that call `coordinator.navigate(to:)`
4. Add `.navigationDestination(for:)` to handle destination rendering
5. Update Preview to provide coordinator instance

### Sheet Presentations

Modal sheets are still managed using `@Published` booleans in coordinators:

```swift
class ProfileCoordinator: Coordinator {
    @Published var showChangePassword = false
    
    func navigate(to destination: Destination) {
        switch destination {
        case .changePassword:
            showChangePassword = true
        // ...
        }
    }
}
```

This allows views to bind to coordinator state:

```swift
.sheet(isPresented: $coordinator.showChangePassword) {
    ChangePasswordView(authService: AuthService.shared)
}
```

## Future Enhancements

- [ ] Add deep linking support through coordinators
- [ ] Implement coordinator-based analytics tracking
- [ ] Add navigation history management
- [ ] Create coordinator protocols for different navigation patterns
- [ ] Add unit tests for coordinator logic
- [ ] Consider adding coordinator delegation for completion handling

## Files Modified

### New Files (Coordinators/)
- `Coordinator.swift` - Base protocol
- `AppCoordinator.swift` - Main app coordinator
- `AuthCoordinator.swift` - Authentication flow
- `TabCoordinator.swift` - Tab navigation
- `HomeCoordinator.swift` - Home feed navigation
- `CampusCoordinator.swift` - Campus feed navigation
- `ProfileCoordinator.swift` - Profile navigation

### Modified Files
- `AnonymousWallIosApp.swift` - Initialize and use AppCoordinator
- `AuthenticationView.swift` - Use AuthCoordinator
- `LoginView.swift` - Use AuthCoordinator
- `RegistrationView.swift` - Use AuthCoordinator
- `TabBarView.swift` - Use TabCoordinator
- `HomeView.swift` - Use HomeCoordinator
- `CampusView.swift` - Use CampusCoordinator
- `ProfileView.swift` - Use ProfileCoordinator
- `Post.swift` - Add Hashable conformance

## Conclusion

The Coordinator Pattern implementation successfully centralizes navigation logic, making the codebase more maintainable, testable, and flexible. All active views now use coordinator-based navigation with no direct `NavigationLink`s, achieving the goals outlined in Issue #12.
