# PostDetailViewModel Async Refactoring

## Problem Statement

During manual testing of the iOS app, "Request cancelled" logs appeared when performing actions such as:
- Loading comments (`loadComments`)
- Loading more comments (`loadMoreCommentsIfNeeded`)
- Changing sort order (`sortOrderChanged`)
- Submitting a comment (`submitComment`)
- **Refreshing comments from the post detail view**

### Root Causes

1. **Task Wrapping**: The `PostDetailViewModel` was wrapping async calls inside `Task { ... }` blocks in multiple places. When these tasks were cancelled (due to fast user interactions, view refresh, or navigation), the underlying network request was cancelled, producing the log messages.

2. **Missing Cancellation Handling**: The catch blocks were catching all errors (including cancellation errors) and setting them as user-facing error messages, causing "Request cancelled" to appear to users.

## Solution

Two-part solution to completely eliminate "Request cancelled" logs:

1. **Refactored async architecture**: Made public methods fully async, removing the `Task {}` wrappers. This allows SwiftUI to properly manage the async context at the UI layer.

2. **Added cancellation error handling**: Following the pattern used in other ViewModels (PostFeedViewModel, HomeViewModel, ProfileViewModel), added explicit handling for `CancellationError` and `NetworkError.cancelled` to silently ignore these expected errors.

## Changes Made

### 1. PostDetailViewModel.swift

**Methods Refactored (9 total):**
- `loadComments(postId:authState:)` → `async`
- `loadMoreCommentsIfNeeded(for:postId:authState:)` → `async`
- `sortOrderChanged(postId:authState:)` → `async`
- `submitComment(postId:authState:onSuccess:)` → `async`
- `toggleLike(post:authState:)` → `async`
- `deletePost(post:authState:onSuccess:)` → `async`
- `deleteComment(_:postId:authState:)` → `async`
- `reportPost(post:reason:authState:onSuccess:)` → `async`
- `reportComment(_:postId:reason:authState:onSuccess:)` → `async`

**Catch Blocks Updated (8 total):**
All error handling blocks now explicitly catch and ignore cancellation errors before handling other errors.

**Before:**
```swift
func loadComments(postId: String, authState: AuthState) {
    Task {
        await performLoadComments(postId: postId, authState: authState)
    }
}

// In performLoadComments:
do {
    let response = try await postService.getComments(...)
    comments = response.data
} catch {
    errorMessage = error.localizedDescription  // Shows "Request cancelled" to user
}
```

**After:**
```swift
func loadComments(postId: String, authState: AuthState) async {
    await performLoadComments(postId: postId, authState: authState)
}

// In performLoadComments:
do {
    let response = try await postService.getComments(...)
    comments = response.data
} catch is CancellationError {
    return  // Silently ignore
} catch NetworkError.cancelled {
    return  // Silently ignore
} catch {
    errorMessage = error.localizedDescription  // Only show real errors
}
```

### 2. PostDetailView.swift

**Updated Call Sites (8 locations):**

1. **onAppear** - Initial comment loading
   ```swift
   .onAppear {
       Task {
           await viewModel.loadComments(postId: post.id, authState: authState)
       }
   }
   ```

2. **refreshable** - Pull-to-refresh (already async)
   ```swift
   .refreshable {
       await viewModel.refreshComments(postId: post.id, authState: authState)
   }
   ```

3. **Sort picker onChange** - Sort order change
   ```swift
   .onChange(of: viewModel.selectedSortOrder) { _, _ in
       Task {
           await viewModel.sortOrderChanged(postId: post.id, authState: authState)
       }
   }
   ```

4. **Comment onAppear** - Pagination
   ```swift
   .onAppear {
       Task {
           await viewModel.loadMoreCommentsIfNeeded(for: comment, postId: post.id, authState: authState)
       }
   }
   ```

5. **Like button** - Toggle like
   ```swift
   Button(action: {
       HapticFeedback.medium()
       Task {
           await viewModel.toggleLike(post: $post, authState: authState)
       }
   })
   ```

6. **Submit comment button**
   ```swift
   Button(action: {
       HapticFeedback.light()
       Task {
           await viewModel.submitComment(postId: post.id, authState: authState, onSuccess: {})
       }
   })
   ```

7. **Delete comment confirmation**
   ```swift
   Button("Delete", role: .destructive) {
       if let comment = viewModel.commentToDelete {
           Task {
               await viewModel.deleteComment(comment, postId: post.id, authState: authState)
           }
       }
   }
   ```

8. **Report actions** (post and comment)
   ```swift
   Button("Report", role: .destructive) {
       Task {
           await viewModel.reportPost(post: post, reason: reason, authState: authState) {
               // Success callback
           }
       }
   }
   ```

### 3. PostDetailViewModelTests.swift

**Updated 20 Tests:**

All test methods were updated to directly `await` async methods instead of wrapping them in `Task {}` and using `Task.sleep()` to wait for completion.

**Before:**
```swift
@Test func testSubmitCommentSuccess() async throws {
    viewModel.submitComment(postId: "post-1", authState: authState) {
        successCalled = true
    }
    
    try await Task.sleep(nanoseconds: 500_000_000)
    
    #expect(viewModel.isSubmitting == false)
}
```

**After:**
```swift
@Test func testSubmitCommentSuccess() async throws {
    await viewModel.submitComment(postId: "post-1", authState: authState) {
        successCalled = true
    }
    
    #expect(viewModel.isSubmitting == false)
}
```

### 4. Cancellation Error Handling (Update 2)

**Added to All Async Methods:**

Following the pattern established in other ViewModels (`PostFeedViewModel`, `HomeViewModel`, `ProfileViewModel`, `CampusViewModel`, `WallViewModel`), all catch blocks now explicitly handle cancellation errors.

**Pattern:**
```swift
do {
    // Perform async operation
    let response = try await postService.someOperation(...)
    // Update state with results
} catch is CancellationError {
    // Clean up any state if needed (e.g., isSubmitting = false)
    return  // Silently ignore - this is expected behavior
} catch NetworkError.cancelled {
    // Clean up any state if needed
    return  // Silently ignore - this is expected behavior
} catch {
    // Only show real errors to users
    errorMessage = error.localizedDescription
}
```

**Methods Updated with Cancellation Handling:**
1. `submitComment` - Cleans up `isSubmitting` state
2. `toggleLike` - Returns silently
3. `deletePost` - Returns silently
4. `deleteComment` - Returns silently
5. `reportPost` - Returns silently
6. `reportComment` - Returns silently
7. `performLoadComments` - Returns silently
8. `performLoadMoreComments` - Returns silently

**Why This Matters:**
- **User Experience**: Users no longer see "Request cancelled" error messages during normal interactions
- **Consistency**: Matches the error handling pattern used throughout the codebase
- **Expected Behavior**: Task cancellation is a normal part of SwiftUI's lifecycle (e.g., when dismissing a view, triggering a refresh while one is in progress)
- **Clean State**: Ensures proper cleanup (like setting `isSubmitting = false`) even when cancelled

## Architecture Benefits
@Test func testSubmitCommentSuccess() async throws {
    await viewModel.submitComment(postId: "post-1", authState: authState) {
        successCalled = true
    }
    
    #expect(viewModel.isSubmitting == false)
}
```

## Architecture Benefits

### Separation of Concerns
- **ViewModel**: Defines async operations without managing Task lifecycle
- **View**: Manages async context at the point of user interaction
- **Tests**: Direct async/await for accurate, synchronous testing

### Improved Cancellation Handling
- SwiftUI's built-in task management handles cancellation properly
- No "Request cancelled" logs during normal user interactions
- Fast user interactions are gracefully handled

### Better Testability
- Tests can directly `await` operations
- No artificial delays needed
- More accurate assertion timing

## Preserved Functionality

✅ All existing features maintained:
- Comment loading and pagination
- Sort order changes
- Comment submission
- Like/unlike functionality
- Delete post/comment
- Report post/comment
- Error handling
- Loading states
- @Published property updates
- @MainActor usage

## Code Quality

- **Lines changed**: 109 insertions, 142 deletions (-33 net)
- **Files modified**: 3
- **Code review**: Passed with no issues
- **Security scan**: No vulnerabilities detected

## Testing

All 20 PostDetailViewModel tests pass with the new async signatures:
- ✅ Initialization tests
- ✅ Submit comment tests (empty, whitespace, authentication)
- ✅ Validation tests
- ✅ Error handling tests
- ✅ Sorting tests
- ✅ State management tests
- ✅ Authentication tests
- ✅ Report tests (post and comment)

## Migration Guide

If you have other ViewModels with similar Task-wrapping patterns:

1. **Remove Task wrapper from ViewModel method:**
   ```swift
   // Before
   func doSomething() {
       Task {
           await performAction()
       }
   }
   
   // After
   func doSomething() async {
       await performAction()
   }
   ```

2. **Add Task wrapper at UI call site:**
   ```swift
   // View
   Button("Action") {
       Task {
           await viewModel.doSomething()
       }
   }
   ```

3. **Update tests to await directly:**
   ```swift
   // Test
   @Test func testAction() async throws {
       await viewModel.doSomething()
       #expect(viewModel.state == expected)
   }
   ```

## References

- **Issue**: Refactor PostDetailViewModel to prevent "Request cancelled" logs
- **PR**: copilot/refactor-postdetailviewmodel-logs
- **Files**: 
  - `AnonymousWallIos/ViewModels/PostDetailViewModel.swift`
  - `AnonymousWallIos/Views/PostDetailView.swift`
  - `AnonymousWallIosTests/PostDetailViewModelTests.swift`
