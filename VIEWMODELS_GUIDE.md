# ViewModels Implementation Guide

This document provides guidance on how to integrate the newly created ViewModels into the SwiftUI Views.

## Overview

The ViewModels layer has been successfully created with 11 ViewModels that extract business logic from the Views. Each ViewModel follows these principles:

1. **Separation of Concerns**: Business logic is in ViewModels, Views handle only UI
2. **Observability**: ViewModels use `@Published` properties for reactive updates
3. **Thread Safety**: ViewModels use `@MainActor` for safe UI updates
4. **Dependency Injection**: ViewModels accept services as dependencies for testability

## Migration Pattern

### Before (Business Logic in View)
```swift
struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        TextField("Email", text: $email)
        SecureField("Password", text: $password)
        Button("Login") { loginUser() }
    }
    
    private func loginUser() {
        isLoading = true
        errorMessage = nil
        Task {
            do {
                let response = try await authService.loginWithPassword(email: email, password: password)
                authState.login(user: response.user, token: response.accessToken)
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}
```

### After (Business Logic in ViewModel)
```swift
struct LoginView: View {
    @EnvironmentObject var authState: AuthState
    @StateObject private var viewModel = LoginViewModel()
    
    var body: some View {
        TextField("Email", text: $viewModel.email)
        SecureField("Password", text: $viewModel.password)
        
        if let error = viewModel.errorMessage {
            Text(error).foregroundColor(.red)
        }
        
        Button("Login") {
            viewModel.login(authState: authState)
        }
        .disabled(viewModel.isLoginButtonDisabled)
    }
}
```

## ViewModels Reference

### Authentication ViewModels

#### LoginViewModel
**Handles**: Login flow, verification codes, countdown timer
**Usage**:
```swift
@StateObject private var viewModel = LoginViewModel()
// Bind to: email, password, verificationCode, loginMethod
// Call: viewModel.login(authState:), viewModel.requestVerificationCode()
```

#### RegistrationViewModel
**Handles**: Registration flow, email verification
**Usage**:
```swift
@StateObject private var viewModel = RegistrationViewModel()
// Bind to: email, verificationCode, codeSent
// Call: viewModel.sendVerificationCode(), viewModel.register(authState:)
```

#### SetPasswordViewModel
**Handles**: Initial password setup validation and submission
**Usage**:
```swift
@StateObject private var viewModel = SetPasswordViewModel()
// Bind to: password, confirmPassword
// Call: viewModel.setPassword(authState:, onSuccess:)
```

#### ChangePasswordViewModel
**Handles**: Password change with old password verification
**Usage**:
```swift
@StateObject private var viewModel = ChangePasswordViewModel()
// Bind to: oldPassword, newPassword, confirmPassword
// Call: viewModel.changePassword(authState:, onSuccess:)
```

#### ForgotPasswordViewModel
**Handles**: Password reset flow with verification
**Usage**:
```swift
@StateObject private var viewModel = ForgotPasswordViewModel()
// Bind to: email, verificationCode, newPassword, codeSent
// Call: viewModel.requestReset(), viewModel.resetPassword(onSuccess:)
```

### Post Management ViewModels

#### CreatePostViewModel
**Handles**: Post creation with validation
**Usage**:
```swift
@StateObject private var viewModel = CreatePostViewModel()
// Bind to: postTitle, postContent, selectedWall
// Call: viewModel.createPost(authState:, onSuccess:)
// Access: viewModel.maxTitleCount, viewModel.maxContentCount
```

#### PostFeedViewModel
**Handles**: Generic post feed with pagination and sorting
**Usage**:
```swift
@StateObject private var viewModel = PostFeedViewModel(wallType: .national)
// Bind to: posts, selectedSortOrder, isLoadingPosts
// Call: viewModel.loadPosts(authState:), viewModel.toggleLike(for:, authState:)
// Call: viewModel.loadMoreIfNeeded(for:, authState:)
```

#### PostDetailViewModel
**Handles**: Post details, comments, interactions
**Usage**:
```swift
@StateObject private var viewModel = PostDetailViewModel()
// Bind to: comments, commentText, selectedSortOrder
// Call: viewModel.loadComments(postId:, authState:)
// Call: viewModel.submitComment(postId:, authState:, onSuccess:)
// Call: viewModel.toggleLike(post:, authState:)
```

### Profile ViewModels

#### ProfileViewModel
**Handles**: User profile, posts, and comments management
**Usage**:
```swift
@StateObject private var viewModel = ProfileViewModel()
// Bind to: myPosts, myComments, selectedSegment, postSortOrder
// Call: viewModel.loadContent(authState:)
// Call: viewModel.toggleLikePost(_:, authState:)
// Call: viewModel.deletePost(_:, authState:)
```

#### EditProfileNameViewModel
**Handles**: Profile name editing
**Usage**:
```swift
@StateObject private var viewModel = EditProfileNameViewModel()
// Bind to: profileName
// Call: viewModel.loadCurrentProfileName(from:)
// Call: viewModel.updateProfileName(authState:, onSuccess:)
```

## Benefits Achieved

### 1. Testability
ViewModels can now be unit tested without UI:
```swift
func testLoginSuccess() async {
    let mockService = MockAuthService()
    let viewModel = LoginViewModel(authService: mockService)
    viewModel.email = "test@example.com"
    viewModel.password = "password123"
    
    await viewModel.login(authState: mockAuthState)
    
    XCTAssertTrue(mockService.loginCalled)
    XCTAssertFalse(viewModel.isLoading)
}
```

### 2. Reusability
PostFeedViewModel is reused across multiple views:
- HomeView (national wall)
- CampusView (campus wall)
- Any future feed implementations

### 3. Maintainability
- Business logic changes don't affect UI code
- UI changes don't affect business logic
- Clear separation of responsibilities

### 4. State Management
- Centralized state in ViewModels
- Reactive updates via @Published
- Thread-safe with @MainActor

## Next Steps

To fully integrate ViewModels into the views:

1. **Replace @State with @StateObject**
   - Change `@State private var` to `@StateObject private var viewModel = ...`

2. **Bind to ViewModel Properties**
   - Replace local state bindings with `$viewModel.property`

3. **Delegate Actions to ViewModel**
   - Move function calls from View to ViewModel methods

4. **Test ViewModels**
   - Write unit tests for each ViewModel
   - Mock dependencies for isolated testing

5. **Remove Business Logic from Views**
   - Keep Views focused on presentation
   - Move all Task/async operations to ViewModels

## Example: Complete Migration

### Original View (Before)
```swift
struct CreatePostView: View {
    @State private var postTitle = ""
    @State private var postContent = ""
    @State private var isPosting = false
    @State private var errorMessage: String?
    
    private func createPost() {
        isPosting = true
        Task {
            do {
                _ = try await PostService.shared.createPost(title: postTitle, content: postContent, ...)
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
            isPosting = false
        }
    }
}
```

### Migrated View (After)
```swift
struct CreatePostView: View {
    @EnvironmentObject var authState: AuthState
    @StateObject private var viewModel = CreatePostViewModel()
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack {
            TextField("Title", text: $viewModel.postTitle)
            TextEditor(text: $viewModel.postContent)
            
            if let error = viewModel.errorMessage {
                Text(error).foregroundColor(.red)
            }
            
            Button("Post") {
                viewModel.createPost(authState: authState, onSuccess: { dismiss() })
            }
            .disabled(viewModel.isPostButtonDisabled)
        }
    }
}
```

## Conclusion

The ViewModels layer provides a solid foundation for implementing the MVVM pattern in this project. All business logic has been extracted into dedicated ViewModels, making the codebase more maintainable, testable, and following iOS development best practices.
