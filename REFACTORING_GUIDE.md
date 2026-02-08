# iOS Swift Refactoring Guide: Step-by-Step Implementation

**Purpose:** Practical guide for transforming this codebase from a functional prototype to an industrial-grade, scalable iOS application.

**Target Audience:** iOS developers implementing the recommendations from CODE_REVIEW_REPORT.md

**Timeline:** 6-8 weeks (3-4 sprints) for critical refactoring

---

## Table of Contents

1. [Quick Wins (Week 1)](#phase-1-quick-wins-week-1)
2. [Protocol-Based Architecture (Week 2-3)](#phase-2-protocol-based-architecture-week-2-3)
3. [Extract ViewModels (Week 4-5)](#phase-3-extract-viewmodels-week-4-5)
4. [Testing Infrastructure (Week 6-8)](#phase-4-testing-infrastructure-week-6-8)
5. [Long-Term Improvements](#phase-5-long-term-improvements)

---

## Phase 1: Quick Wins (Week 1)

### ✅ 1.1 Fix Memory Leaks (COMPLETED)

**Status:** ✅ Implemented in commit 9b0d1ca

**Files Modified:**
- `LoginView.swift`
- `RegistrationView.swift`
- `ForgotPasswordView.swift`

### 🔧 1.2 Add Token Expiration Validation

**Priority:** 🔴 Critical  
**Effort:** 4 hours  
**Impact:** Prevents 401 errors, improves user experience

**Implementation:**

#### Step 1: Add JWT Decoder Utility

Create new file: `Utils/JWTDecoder.swift`

```swift
import Foundation

struct JWTDecoder {
    /// Decodes a JWT token and extracts the expiration date
    /// - Parameter token: JWT token string
    /// - Returns: Expiration date, or nil if invalid/no expiration
    static func getExpirationDate(from token: String) -> Date? {
        let segments = token.components(separatedBy: ".")
        guard segments.count > 1 else { return nil }
        
        // JWT payload is the second segment
        let payloadSegment = segments[1]
        
        // Add padding if needed for base64 decoding
        var base64 = payloadSegment
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        
        while base64.count % 4 != 0 {
            base64.append("=")
        }
        
        guard let data = Data(base64Encoded: base64) else { return nil }
        
        do {
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let exp = json["exp"] as? TimeInterval {
                return Date(timeIntervalSince1970: exp)
            }
        } catch {
            print("Failed to decode JWT payload: \(error)")
        }
        
        return nil
    }
    
    /// Checks if a token is expired or will expire within the buffer period
    /// - Parameters:
    ///   - token: JWT token string
    ///   - bufferSeconds: Buffer time in seconds (default: 300 = 5 minutes)
    /// - Returns: true if token is expired or will expire soon
    static func isTokenExpired(_ token: String, bufferSeconds: TimeInterval = 300) -> Bool {
        guard let expirationDate = getExpirationDate(from: token) else {
            // If we can't decode, assume expired for safety
            return true
        }
        
        // Check if token expires within buffer period
        let expirationWithBuffer = expirationDate.addingTimeInterval(-bufferSeconds)
        return Date() >= expirationWithBuffer
    }
}
```

#### Step 2: Modify AuthState to Validate Token

**File:** `Models/AuthState.swift`

```swift
// Add at top of file
import Foundation
import SwiftUI

class AuthState: ObservableObject {
    // ... existing properties ...
    
    // MODIFY loadAuthState() method
    private func loadAuthState() {
        isAuthenticated = UserDefaults.standard.bool(forKey: AppConfiguration.UserDefaultsKeys.isAuthenticated)
        needsPasswordSetup = UserDefaults.standard.bool(forKey: AppConfiguration.UserDefaultsKeys.needsPasswordSetup)
        
        // Load token from Keychain
        authToken = KeychainHelper.shared.get(keychainAuthTokenKey)
        
        // ✅ NEW: Validate token expiration
        if let token = authToken {
            if JWTDecoder.isTokenExpired(token) {
                print("⚠️ Stored token is expired, logging out")
                clearAuthState()
                return
            }
        }
        
        if let userId = UserDefaults.standard.string(forKey: AppConfiguration.UserDefaultsKeys.userId),
           let userEmail = UserDefaults.standard.string(forKey: AppConfiguration.UserDefaultsKeys.userEmail) {
            let isVerified = UserDefaults.standard.bool(forKey: AppConfiguration.UserDefaultsKeys.userIsVerified)
            let profileName = UserDefaults.standard.string(forKey: AppConfiguration.UserDefaultsKeys.userProfileName) ?? "Anonymous"
            let passwordSet = !needsPasswordSetup
            currentUser = User(id: userId, email: userEmail, profileName: profileName, isVerified: isVerified, passwordSet: passwordSet, createdAt: "")
        }
    }
}
```

#### Step 3: Test Token Validation

**Test Scenarios:**
1. Valid token → User stays authenticated
2. Expired token → User auto-logged out
3. Token expiring in 4 minutes → User auto-logged out (buffer)
4. Invalid token format → User auto-logged out

**Manual Testing:**
```swift
// Add temporary test in AuthState.init() for development
#if DEBUG
func testTokenValidation() {
    // Test expired token
    let expiredToken = "eyJ...expired_token_here"
    assert(JWTDecoder.isTokenExpired(expiredToken) == true)
    
    // Test valid token (won't expire for 1 hour)
    let validToken = authToken ?? ""
    if !validToken.isEmpty {
        print("Token expiration: \(JWTDecoder.getExpirationDate(from: validToken) ?? Date())")
    }
}
#endif
```

### 🔧 1.3 Add Network Request Timeout Configuration

**Priority:** 🟡 Medium  
**Effort:** 2 hours  
**Impact:** Better handling of slow networks

**File:** `Networking/NetworkClient.swift`

```swift
class NetworkClient: NetworkClientProtocol {
    static let shared = NetworkClient()
    
    private let session: URLSession
    private let config = AppConfiguration.shared
    
    private init(session: URLSession? = nil) {
        // ✅ NEW: Configure session with timeout
        if let customSession = session {
            self.session = customSession
        } else {
            let configuration = URLSessionConfiguration.default
            configuration.timeoutIntervalForRequest = 30  // 30 seconds
            configuration.timeoutIntervalForResource = 60  // 1 minute for large uploads
            self.session = URLSession(configuration: configuration)
        }
    }
    
    // ... rest of class ...
}
```

---

## Phase 2: Protocol-Based Architecture (Week 2-3)

### 🔧 2.1 Create Service Protocols

**Priority:** 🟠 High  
**Effort:** 1 week  
**Impact:** Enables testing, loose coupling, flexibility

#### Step 1: Create Protocols Directory

```bash
mkdir -p AnonymousWallIos/Protocols
```

#### Step 2: Create AuthServiceProtocol

**File:** `Protocols/AuthServiceProtocol.swift`

```swift
import Foundation

/// Protocol defining authentication service operations
/// Implement this protocol to create mock services for testing
protocol AuthServiceProtocol {
    // Email Verification
    func sendEmailVerificationCode(email: String, purpose: String) async throws -> VerificationCodeResponse
    
    // Registration
    func registerWithEmail(email: String, code: String) async throws -> AuthResponse
    
    // Login
    func loginWithEmailCode(email: String, code: String) async throws -> AuthResponse
    func loginWithPassword(email: String, password: String) async throws -> AuthResponse
    
    // Password Management
    func setPassword(password: String, token: String, userId: String) async throws
    func changePassword(oldPassword: String, newPassword: String, token: String, userId: String) async throws
    func requestPasswordReset(email: String) async throws
    func resetPassword(email: String, code: String, newPassword: String) async throws -> AuthResponse
    
    // Profile
    func updateProfileName(profileName: String, token: String, userId: String) async throws -> User
}
```

#### Step 3: Make AuthService Conform to Protocol

**File:** `Services/AuthService.swift`

```swift
// Change class declaration
class AuthService: AuthServiceProtocol {
    // ✅ NEW: Make singleton optional for testing
    static let shared = AuthService()
    
    private let config = AppConfiguration.shared
    private let networkClient: NetworkClientProtocol  // Use protocol
    
    // ✅ NEW: Allow injection for testing
    init(networkClient: NetworkClientProtocol = NetworkClient.shared) {
        self.networkClient = networkClient
    }
    
    // ... existing methods remain the same ...
}
```

#### Step 4: Create PostServiceProtocol

**File:** `Protocols/PostServiceProtocol.swift`

```swift
import Foundation

protocol PostServiceProtocol {
    // Post Operations
    func fetchPosts(
        token: String,
        userId: String,
        wall: WallType,
        page: Int,
        limit: Int,
        sort: SortOrder
    ) async throws -> PostListResponse
    
    func getPost(postId: String, token: String, userId: String) async throws -> Post
    func createPost(title: String, content: String, wall: WallType, token: String, userId: String) async throws -> Post
    func toggleLike(postId: String, token: String, userId: String) async throws -> LikeResponse
    func hidePost(postId: String, token: String, userId: String) async throws -> HidePostResponse
    
    // Comment Operations
    func addComment(postId: String, text: String, token: String, userId: String) async throws -> Comment
    func getComments(postId: String, token: String, userId: String, page: Int, limit: Int, sort: SortOrder) async throws -> CommentListResponse
    func hideComment(postId: String, commentId: String, token: String, userId: String) async throws -> HidePostResponse
    
    // User Operations
    func getUserComments(token: String, userId: String, page: Int, limit: Int, sort: SortOrder) async throws -> CommentListResponse
    func getUserPosts(token: String, userId: String, page: Int, limit: Int, sort: SortOrder) async throws -> PostListResponse
}
```

#### Step 5: Update PostService

**File:** `Services/PostService.swift`

```swift
class PostService: PostServiceProtocol {
    static let shared = PostService()
    
    private let config = AppConfiguration.shared
    private let networkClient: NetworkClientProtocol
    
    // ✅ NEW: Allow injection
    init(networkClient: NetworkClientProtocol = NetworkClient.shared) {
        self.networkClient = networkClient
    }
    
    // ... existing methods remain the same ...
}
```

### 🔧 2.2 Create Mock Services for Testing

**File:** `AnonymousWallIosTests/Mocks/MockAuthService.swift`

```swift
import Foundation
@testable import AnonymousWallIos

class MockAuthService: AuthServiceProtocol {
    // Control test behavior
    var loginResult: Result<AuthResponse, Error>?
    var registerResult: Result<AuthResponse, Error>?
    var sendCodeResult: Result<VerificationCodeResponse, Error>?
    
    // Track method calls
    var loginCallCount = 0
    var lastLoginEmail: String?
    var lastLoginPassword: String?
    
    func loginWithPassword(email: String, password: String) async throws -> AuthResponse {
        loginCallCount += 1
        lastLoginEmail = email
        lastLoginPassword = password
        
        if let result = loginResult {
            switch result {
            case .success(let response):
                return response
            case .failure(let error):
                throw error
            }
        }
        
        fatalError("Mock not configured - set loginResult before calling")
    }
    
    func registerWithEmail(email: String, code: String) async throws -> AuthResponse {
        if let result = registerResult {
            switch result {
            case .success(let response): return response
            case .failure(let error): throw error
            }
        }
        fatalError("Mock not configured")
    }
    
    func sendEmailVerificationCode(email: String, purpose: String) async throws -> VerificationCodeResponse {
        if let result = sendCodeResult {
            switch result {
            case .success(let response): return response
            case .failure(let error): throw error
            }
        }
        fatalError("Mock not configured")
    }
    
    // ... implement other protocol methods with similar pattern ...
    
    func loginWithEmailCode(email: String, code: String) async throws -> AuthResponse {
        fatalError("Not implemented in mock")
    }
    
    func setPassword(password: String, token: String, userId: String) async throws {
        // No-op for mock
    }
    
    func changePassword(oldPassword: String, newPassword: String, token: String, userId: String) async throws {
        // No-op for mock
    }
    
    func requestPasswordReset(email: String) async throws {
        // No-op for mock
    }
    
    func resetPassword(email: String, code: String, newPassword: String) async throws -> AuthResponse {
        fatalError("Not implemented in mock")
    }
    
    func updateProfileName(profileName: String, token: String, userId: String) async throws -> User {
        fatalError("Not implemented in mock")
    }
}
```

**File:** `AnonymousWallIosTests/Mocks/MockPostService.swift`

```swift
import Foundation
@testable import AnonymousWallIos

class MockPostService: PostServiceProtocol {
    var fetchPostsResult: Result<PostListResponse, Error>?
    var createPostResult: Result<Post, Error>?
    var toggleLikeResult: Result<LikeResponse, Error>?
    
    var fetchPostsCallCount = 0
    var lastWallType: WallType?
    var lastPage: Int?
    
    func fetchPosts(
        token: String,
        userId: String,
        wall: WallType = .campus,
        page: Int = 1,
        limit: Int = 20,
        sort: SortOrder = .newest
    ) async throws -> PostListResponse {
        fetchPostsCallCount += 1
        lastWallType = wall
        lastPage = page
        
        if let result = fetchPostsResult {
            switch result {
            case .success(let response): return response
            case .failure(let error): throw error
            }
        }
        
        fatalError("Mock not configured")
    }
    
    // ... implement other methods ...
    
    func getPost(postId: String, token: String, userId: String) async throws -> Post {
        fatalError("Not implemented in mock")
    }
    
    func createPost(title: String, content: String, wall: WallType, token: String, userId: String) async throws -> Post {
        if let result = createPostResult {
            switch result {
            case .success(let post): return post
            case .failure(let error): throw error
            }
        }
        fatalError("Mock not configured")
    }
    
    func toggleLike(postId: String, token: String, userId: String) async throws -> LikeResponse {
        if let result = toggleLikeResult {
            switch result {
            case .success(let response): return response
            case .failure(let error): throw error
            }
        }
        fatalError("Mock not configured")
    }
    
    func hidePost(postId: String, token: String, userId: String) async throws -> HidePostResponse {
        return HidePostResponse(message: "Post hidden")
    }
    
    func addComment(postId: String, text: String, token: String, userId: String) async throws -> Comment {
        fatalError("Not implemented in mock")
    }
    
    func getComments(postId: String, token: String, userId: String, page: Int, limit: Int, sort: SortOrder) async throws -> CommentListResponse {
        fatalError("Not implemented in mock")
    }
    
    func hideComment(postId: String, commentId: String, token: String, userId: String) async throws -> HidePostResponse {
        return HidePostResponse(message: "Comment hidden")
    }
    
    func getUserComments(token: String, userId: String, page: Int, limit: Int, sort: SortOrder) async throws -> CommentListResponse {
        fatalError("Not implemented in mock")
    }
    
    func getUserPosts(token: String, userId: String, page: Int, limit: Int, sort: SortOrder) async throws -> PostListResponse {
        fatalError("Not implemented in mock")
    }
}
```

---

## Phase 3: Extract ViewModels (Week 4-5)

### 🔧 3.1 Create ViewModels Directory

```bash
mkdir -p AnonymousWallIos/ViewModels
```

### 🔧 3.2 Extract HomeViewModel

**Priority:** 🟠 High  
**Effort:** 2 days  
**Impact:** Makes HomeView testable, reduces complexity

#### Step 1: Create HomeViewModel

**File:** `ViewModels/HomeViewModel.swift`

```swift
import Foundation
import SwiftUI

@MainActor
class HomeViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var posts: [Post] = []
    @Published var isLoadingPosts = false
    @Published var isLoadingMore = false
    @Published var errorMessage: String?
    @Published var selectedSortOrder: SortOrder = .newest
    @Published var showSetPassword = false
    
    // MARK: - Private Properties
    
    private(set) var currentPage = 1
    private(set) var hasMorePages = true
    private var loadTask: Task<Void, Never>?
    
    private let postService: PostServiceProtocol
    private let authState: AuthState
    
    // MARK: - Initialization
    
    init(postService: PostServiceProtocol, authState: AuthState) {
        self.postService = postService
        self.authState = authState
    }
    
    // MARK: - Public Methods
    
    func onAppear() {
        // Show password setup if needed (only once)
        if authState.needsPasswordSetup && !authState.hasShownPasswordSetup {
            authState.markPasswordSetupShown()
            Task {
                try? await Task.sleep(nanoseconds: 500_000_000)
                showSetPassword = true
            }
        }
        
        // Load posts
        loadTask = Task {
            await loadPosts()
        }
    }
    
    func onDisappear() {
        loadTask?.cancel()
    }
    
    func onSortOrderChanged() {
        HapticFeedback.selection()
        loadTask?.cancel()
        posts = []
        resetPagination()
        loadTask = Task {
            await loadPosts()
        }
    }
    
    func refreshPosts() async {
        loadTask?.cancel()
        resetPagination()
        loadTask = Task {
            await loadPosts()
        }
        await loadTask?.value
    }
    
    func loadMoreIfNeeded(for post: Post) {
        guard post.id == posts.last?.id else { return }
        loadMoreIfNeeded()
    }
    
    func toggleLike(for post: Post) {
        guard let token = authState.authToken,
              let userId = authState.currentUser?.id else {
            return
        }
        
        Task {
            do {
                let response = try await postService.toggleLike(
                    postId: post.id,
                    token: token,
                    userId: userId
                )
                
                if let index = posts.firstIndex(where: { $0.id == post.id }) {
                    posts[index] = posts[index].withUpdatedLike(
                        liked: response.liked,
                        likes: response.likeCount
                    )
                }
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
    
    func deletePost(_ post: Post) {
        guard let token = authState.authToken,
              let userId = authState.currentUser?.id else {
            errorMessage = "Authentication required to delete post."
            return
        }
        
        Task {
            do {
                _ = try await postService.hidePost(
                    postId: post.id,
                    token: token,
                    userId: userId
                )
                resetPagination()
                await loadPosts()
            } catch {
                errorMessage = getErrorMessage(for: error)
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func resetPagination() {
        currentPage = 1
        hasMorePages = true
    }
    
    private func loadPosts() async {
        guard let token = authState.authToken,
              let userId = authState.currentUser?.id else {
            return
        }
        
        isLoadingPosts = true
        errorMessage = nil
        defer { isLoadingPosts = false }
        
        do {
            let response = try await postService.fetchPosts(
                token: token,
                userId: userId,
                wall: .national,
                page: currentPage,
                limit: 20,
                sort: selectedSortOrder
            )
            posts = response.data
            hasMorePages = currentPage < response.pagination.totalPages
        } catch is CancellationError {
            return
        } catch NetworkError.cancelled {
            return
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    private func loadMoreIfNeeded() {
        guard !isLoadingMore && hasMorePages else { return }
        
        Task {
            guard !isLoadingMore && hasMorePages else { return }
            isLoadingMore = true
            await loadMorePosts()
        }
    }
    
    private func loadMorePosts() async {
        guard let token = authState.authToken,
              let userId = authState.currentUser?.id else {
            isLoadingMore = false
            return
        }
        
        defer { isLoadingMore = false }
        
        let nextPage = currentPage + 1
        
        do {
            let response = try await postService.fetchPosts(
                token: token,
                userId: userId,
                wall: .national,
                page: nextPage,
                limit: 20,
                sort: selectedSortOrder
            )
            
            currentPage = nextPage
            posts.append(contentsOf: response.data)
            hasMorePages = currentPage < response.pagination.totalPages
        } catch is CancellationError {
            return
        } catch NetworkError.cancelled {
            return
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    private func getErrorMessage(for error: Error) -> String {
        if let networkError = error as? NetworkError {
            switch networkError {
            case .unauthorized:
                return "Session expired. Please log in again."
            case .forbidden:
                return "You don't have permission to delete this post."
            case .notFound:
                return "Post not found."
            case .noConnection:
                return "No internet connection. Please check your network."
            default:
                return "Failed to delete post. Please try again."
            }
        }
        return "Failed to delete post. Please try again."
    }
}
```

#### Step 2: Update HomeView to Use ViewModel

**File:** `Views/HomeView.swift`

```swift
import SwiftUI

struct HomeView: View {
    @EnvironmentObject var authState: AuthState
    @StateObject private var viewModel: HomeViewModel
    
    // Minimum height for scrollable content
    private let minimumScrollableHeight: CGFloat = 300
    
    init(viewModel: HomeViewModel? = nil) {
        // Allow injection for testing, or create default
        if let vm = viewModel {
            self._viewModel = StateObject(wrappedValue: vm)
        } else {
            // Default initialization - will be properly injected from App
            let authState = AuthState()  // Temporary, will be replaced
            self._viewModel = StateObject(wrappedValue: HomeViewModel(
                postService: PostService.shared,
                authState: authState
            ))
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Password setup alert banner
                if authState.needsPasswordSetup {
                    PasswordSetupBanner(action: { viewModel.showSetPassword = true })
                }
                
                // Sorting control
                SortingPicker(selection: $viewModel.selectedSortOrder)
                    .onChange(of: viewModel.selectedSortOrder) { _, _ in
                        viewModel.onSortOrderChanged()
                    }
                
                // Post list
                ScrollView {
                    if viewModel.isLoadingPosts && viewModel.posts.isEmpty {
                        LoadingView(height: minimumScrollableHeight)
                    } else if viewModel.posts.isEmpty && !viewModel.isLoadingPosts {
                        EmptyStateView(
                            icon: "globe.americas.fill",
                            title: "No national posts yet",
                            subtitle: "Be the first to post!",
                            height: minimumScrollableHeight
                        )
                    } else {
                        PostListView(
                            posts: viewModel.posts,
                            currentUserId: authState.currentUser?.id,
                            isLoadingMore: viewModel.isLoadingMore,
                            onLike: viewModel.toggleLike,
                            onDelete: viewModel.deletePost,
                            onPostAppear: viewModel.loadMoreIfNeeded
                        )
                    }
                }
                .refreshable {
                    await viewModel.refreshPosts()
                }
                
                // Error message
                if let errorMessage = viewModel.errorMessage {
                    ErrorMessageView(message: errorMessage)
                }
            }
            .navigationTitle("National")
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $viewModel.showSetPassword) {
            SetPasswordView()
        }
        .onAppear {
            viewModel.onAppear()
        }
        .onDisappear {
            viewModel.onDisappear()
        }
    }
}

// MARK: - Subviews

private struct PasswordSetupBanner: View {
    let action: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
            Text("Please set up your password to secure your account")
                .font(.caption)
                .foregroundColor(.primary)
            Spacer()
            Button("Set Now") {
                action()
            }
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundColor(.blue)
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(8)
        .padding()
    }
}

private struct SortingPicker: View {
    @Binding var selection: SortOrder
    
    var body: some View {
        Picker("Sort Order", selection: $selection) {
            ForEach(SortOrder.feedOptions, id: \.self) { option in
                Text(option.displayName).tag(option)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

private struct LoadingView: View {
    let height: CGFloat
    
    var body: some View {
        VStack {
            Spacer()
            ProgressView("Loading posts...")
            Spacer()
        }
        .frame(maxWidth: .infinity, minHeight: height)
    }
}

private struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String
    let height: CGFloat
    
    var body: some View {
        VStack {
            Spacer()
            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(Color.tealPurpleGradient)
                        .frame(width: 100, height: 100)
                        .blur(radius: 30)
                    
                    Image(systemName: icon)
                        .font(.system(size: 60))
                        .foregroundStyle(Color.tealPurpleGradient)
                }
                
                VStack(spacing: 8) {
                    Text(title)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.primary)
                    Text(subtitle)
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, minHeight: height)
    }
}

private struct PostListView: View {
    let posts: [Post]
    let currentUserId: String?
    let isLoadingMore: Bool
    let onLike: (Post) -> Void
    let onDelete: (Post) -> Void
    let onPostAppear: (Post) -> Void
    
    var body: some View {
        LazyVStack(spacing: 12) {
            ForEach(posts) { post in
                NavigationLink(destination: destinationView(for: post)) {
                    PostRowView(
                        post: post,
                        isOwnPost: post.author.id == currentUserId,
                        onLike: { onLike(post) },
                        onDelete: { onDelete(post) }
                    )
                }
                .buttonStyle(PlainButtonStyle())
                .onAppear {
                    onPostAppear(post)
                }
            }
            
            if isLoadingMore {
                HStack {
                    Spacer()
                    ProgressView()
                        .padding()
                    Spacer()
                }
            }
        }
        .padding()
    }
    
    @ViewBuilder
    private func destinationView(for post: Post) -> some View {
        if let index = posts.firstIndex(where: { $0.id == post.id }) {
            PostDetailView(post: Binding(
                get: { posts[index] },
                set: { _ in }  // Handle in ViewModel
            ))
        }
    }
}

private struct ErrorMessageView: View {
    let message: String
    
    var body: some View {
        Text(message)
            .foregroundColor(.red)
            .font(.caption)
            .padding()
    }
}

#Preview {
    let authState = AuthState()
    let viewModel = HomeViewModel(
        postService: PostService.shared,
        authState: authState
    )
    
    return HomeView(viewModel: viewModel)
        .environmentObject(authState)
}
```

#### Step 3: Update App to Inject ViewModel

**File:** `AnonymousWallIosApp.swift`

```swift
@main
struct AnonymousWallIosApp: App {
    @StateObject private var authState = AuthState()
    
    // Create services (could be in a DI container)
    private let postService: PostServiceProtocol = PostService.shared
    
    var body: some Scene {
        WindowGroup {
            if authState.isAuthenticated {
                TabBarView()
                    .environmentObject(authState)
            } else {
                AuthenticationView()
                    .environmentObject(authState)
            }
        }
    }
}
```

### 🔧 3.3 Create Similar ViewModels

Repeat the pattern for:
- `WallViewModel` (for WallView)
- `ProfileViewModel` (for ProfileView)
- `LoginViewModel` (for LoginView)
- `PostDetailViewModel` (for PostDetailView)

---

## Phase 4: Testing Infrastructure (Week 6-8)

### 🔧 4.1 Set Up Test Target

**File:** `AnonymousWallIosTests/AnonymousWallIosTests.swift`

```swift
import XCTest
@testable import AnonymousWallIos

final class HomeViewModelTests: XCTestCase {
    var sut: HomeViewModel!
    var mockPostService: MockPostService!
    var mockAuthState: AuthState!
    
    @MainActor
    override func setUp() {
        super.setUp()
        mockPostService = MockPostService()
        mockAuthState = AuthState()
        
        // Set up authenticated state
        let testUser = User(
            id: "test-user-123",
            email: "test@test.com",
            profileName: "Test User",
            isVerified: true,
            passwordSet: true,
            createdAt: ""
        )
        mockAuthState.login(user: testUser, token: "test-token")
        
        sut = HomeViewModel(
            postService: mockPostService,
            authState: mockAuthState
        )
    }
    
    override func tearDown() {
        sut = nil
        mockPostService = nil
        mockAuthState = nil
        super.tearDown()
    }
    
    // MARK: - Load Posts Tests
    
    @MainActor
    func testLoadPosts_Success_UpdatesPostsArray() async {
        // Given
        let testPosts = [
            Post(
                id: "1",
                title: "Test Post 1",
                content: "Content 1",
                wall: "NATIONAL",
                likes: 5,
                comments: 2,
                liked: false,
                author: Post.Author(id: "author1", profileName: "Author 1", isAnonymous: true),
                createdAt: "2026-01-01",
                updatedAt: "2026-01-01"
            ),
            Post(
                id: "2",
                title: "Test Post 2",
                content: "Content 2",
                wall: "NATIONAL",
                likes: 10,
                comments: 5,
                liked: true,
                author: Post.Author(id: "author2", profileName: "Author 2", isAnonymous: true),
                createdAt: "2026-01-02",
                updatedAt: "2026-01-02"
            )
        ]
        
        let response = PostListResponse(
            data: testPosts,
            pagination: PostListResponse.Pagination(
                page: 1,
                limit: 20,
                total: 2,
                totalPages: 1
            )
        )
        mockPostService.fetchPostsResult = .success(response)
        
        // When
        sut.onAppear()
        
        // Wait for async operation
        try? await Task.sleep(nanoseconds: 100_000_000)  // 0.1 seconds
        
        // Then
        XCTAssertEqual(sut.posts.count, 2)
        XCTAssertEqual(sut.posts[0].id, "1")
        XCTAssertEqual(sut.posts[1].id, "2")
        XCTAssertFalse(sut.isLoadingPosts)
        XCTAssertNil(sut.errorMessage)
        XCTAssertEqual(mockPostService.fetchPostsCallCount, 1)
        XCTAssertEqual(mockPostService.lastWallType, .national)
    }
    
    @MainActor
    func testLoadPosts_Failure_SetsErrorMessage() async {
        // Given
        mockPostService.fetchPostsResult = .failure(NetworkError.noConnection)
        
        // When
        sut.onAppear()
        
        // Wait for async operation
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // Then
        XCTAssertTrue(sut.posts.isEmpty)
        XCTAssertNotNil(sut.errorMessage)
        XCTAssertFalse(sut.isLoadingPosts)
    }
    
    @MainActor
    func testLoadPosts_WhileUnauthenticated_DoesNothing() async {
        // Given
        mockAuthState.logout()
        
        // When
        sut.onAppear()
        
        // Wait for async operation
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // Then
        XCTAssertTrue(sut.posts.isEmpty)
        XCTAssertEqual(mockPostService.fetchPostsCallCount, 0)
    }
    
    // MARK: - Toggle Like Tests
    
    @MainActor
    func testToggleLike_Success_UpdatesPostLikeStatus() async {
        // Given
        let testPost = Post(
            id: "1",
            title: "Test Post",
            content: "Content",
            wall: "NATIONAL",
            likes: 5,
            comments: 2,
            liked: false,
            author: Post.Author(id: "author1", profileName: "Author", isAnonymous: true),
            createdAt: "2026-01-01",
            updatedAt: "2026-01-01"
        )
        sut.posts = [testPost]
        
        mockPostService.toggleLikeResult = .success(
            LikeResponse(liked: true, likeCount: 6)
        )
        
        // When
        sut.toggleLike(for: testPost)
        
        // Wait for async operation
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // Then
        XCTAssertEqual(sut.posts[0].liked, true)
        XCTAssertEqual(sut.posts[0].likes, 6)
    }
    
    // MARK: - Sorting Tests
    
    @MainActor
    func testChangeSortOrder_ReloadsPostsWithNewSort() async {
        // Given
        mockPostService.fetchPostsResult = .success(
            PostListResponse(data: [], pagination: PostListResponse.Pagination(
                page: 1, limit: 20, total: 0, totalPages: 0
            ))
        )
        
        // When
        sut.selectedSortOrder = .mostLiked
        sut.onSortOrderChanged()
        
        // Wait for async operation
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // Then
        // Verify posts were cleared and reloaded
        XCTAssertEqual(mockPostService.fetchPostsCallCount, 1)
    }
}
```

---

## Phase 5: Long-Term Improvements

### 🔧 5.1 Implement Coordinator Pattern

**Priority:** 🟡 Medium  
**Effort:** 1 week  
**Impact:** Better navigation management

**File:** `Coordinators/AppCoordinator.swift`

```swift
import SwiftUI

@MainActor
class AppCoordinator: ObservableObject {
    @Published var path = NavigationPath()
    
    enum Route: Hashable {
        case postDetail(Post)
        case createPost
        case profile
        case editProfileName
        case changePassword
        case setPassword
    }
    
    func navigate(to route: Route) {
        path.append(route)
    }
    
    func pop() {
        if !path.isEmpty {
            path.removeLast()
        }
    }
    
    func popToRoot() {
        path = NavigationPath()
    }
    
    @ViewBuilder
    func destination(for route: Route) -> some View {
        switch route {
        case .postDetail(let post):
            PostDetailView(post: .constant(post))
        case .createPost:
            CreatePostView(onPostCreated: {})
        case .profile:
            ProfileView()
        case .editProfileName:
            EditProfileNameView()
        case .changePassword:
            ChangePasswordView()
        case .setPassword:
            SetPasswordView()
        }
    }
}
```

### 🔧 5.2 Add Logging Infrastructure

**File:** `Utils/Logger.swift`

```swift
import Foundation
import os.log

enum LogLevel {
    case debug, info, warning, error
    
    var osLogType: OSLogType {
        switch self {
        case .debug: return .debug
        case .info: return .info
        case .warning: return .default
        case .error: return .error
        }
    }
}

struct Logger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.anonymouswall"
    
    static func log(
        _ message: String,
        level: LogLevel = .info,
        category: String = "General",
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        #if DEBUG
        let logger = os.Logger(subsystem: subsystem, category: category)
        let fileName = (file as NSString).lastPathComponent
        let logMessage = "[\(fileName):\(line)] \(function) - \(message)"
        logger.log(level: level.osLogType, "\(logMessage)")
        #endif
    }
    
    static func debug(_ message: String, category: String = "General") {
        log(message, level: .debug, category: category)
    }
    
    static func info(_ message: String, category: String = "General") {
        log(message, level: .info, category: category)
    }
    
    static func warning(_ message: String, category: String = "General") {
        log(message, level: .warning, category: category)
    }
    
    static func error(_ message: String, category: String = "General") {
        log(message, level: .error, category: category)
    }
}

// Usage:
// Logger.debug("Post loaded", category: "Networking")
// Logger.error("Failed to authenticate", category: "Auth")
```

---

## Testing Checklist

After each phase, verify:

### Phase 1 Verification
- [ ] App launches without crashes
- [ ] Expired tokens trigger logout
- [ ] Network timeouts handled gracefully
- [ ] Timer memory leaks fixed (use Instruments)

### Phase 2 Verification
- [ ] Mock services can be instantiated
- [ ] Protocol conformance compiles
- [ ] Services still work with singleton access
- [ ] No breaking changes to existing views

### Phase 3 Verification
- [ ] Views still render correctly
- [ ] All user interactions work
- [ ] @EnvironmentObject injection works
- [ ] ViewModels properly deallocate

### Phase 4 Verification
- [ ] Unit tests run and pass
- [ ] Test coverage > 70%
- [ ] Mock services behave correctly
- [ ] Tests run in < 10 seconds

---

## Migration Strategy

### Option A: Big Bang (Risky)
- Refactor everything at once
- High risk of breaking production
- Fastest timeline (2 weeks)
- ⚠️ Not recommended

### Option B: Gradual Migration (Recommended)
- One view at a time
- Keep old and new patterns coexisting
- Lower risk, easier to test
- Timeline: 6-8 weeks
- ✅ **Recommended approach**

### Option C: Feature Freeze
- Stop new feature development
- Focus 100% on refactoring
- Clean slate after completion
- Timeline: 4 weeks
- ⚠️ Product may object

**Recommendation:** Use **Option B** - migrate one feature at a time, starting with least critical views (Market, Internship) and ending with most critical (Home, Profile).

---

## Success Metrics

Track these metrics to measure refactoring success:

| Metric | Before | Target After |
|--------|--------|--------------|
| Unit test coverage | 0% | 80% |
| Largest view file | 750 lines | < 300 lines |
| Average view complexity | High | Medium |
| Build time | Baseline | < +10% |
| App launch time | Baseline | < +5% |
| Memory leaks | 3 known | 0 |
| Testable services | 0% | 100% |
| Code duplication | High | Low |

---

## Resources

### Apple Documentation
- [SwiftUI MVVM Best Practices](https://developer.apple.com/documentation/swiftui)
- [Concurrency Programming Guide](https://docs.swift.org/swift-book/LanguageGuide/Concurrency.html)
- [Testing Your App](https://developer.apple.com/documentation/xcode/testing-your-app)

### Recommended Reading
- "Clean Architecture" by Robert C. Martin
- "iOS Unit Testing by Example" by Jon Reid
- "Modern Concurrency in Swift" by Kodeco

---

**Last Updated:** February 8, 2026  
**Next Review:** After Phase 2 completion
