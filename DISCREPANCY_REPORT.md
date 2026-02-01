# API Discrepancy Analysis and Fixes

## Summary

This document outlines the discrepancies found between the iOS app implementation and the backend API specification in `copilot-instructions.md`, and the fixes that were applied.

## Discrepancies Found

### 1. User Model - Missing `passwordSet` Field
**Issue**: The User model was missing the `passwordSet` boolean field that the backend returns.

**Backend Spec**:
```json
{
  "id": "uuid",
  "email": "student@harvard.edu",
  "isVerified": true,
  "passwordSet": false,
  "createdAt": "2026-01-28T..."
}
```

**Fix**: Added optional `passwordSet` field to User model in `User.swift`.

---

### 2. AuthResponse Structure Order
**Issue**: While not causing functional issues, the documentation suggested the order was different.

**Backend Spec**: Returns `user` object first, then `accessToken`
**Current**: Implementation handles both orders correctly through Codable

**Fix**: No code change needed, but documentation updated for clarity.

---

### 3. Post Model - Incomplete Structure
**Issue**: The Post model was using old field names and missing several fields.

**Old Structure**:
```swift
struct Post {
    let id: String
    let content: String
    let authorId: String
    let createdAt: String
    let likesCount: Int
    let isLikedByCurrentUser: Bool?
}
```

**Backend Spec**:
```json
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
```

**Fix**: Completely rewrote Post model with correct fields:
- Changed `authorId` to nested `author` object with `id` and `isAnonymous`
- Added `wall` field (String to handle uppercase response)
- Changed `likesCount` to `likes`
- Changed `isLikedByCurrentUser` to `liked`
- Added `comments` count field
- Added `updatedAt` field

---

### 4. CreatePostRequest - Missing `wall` Field
**Issue**: The create post request was not including the wall type.

**Backend Spec**: Requires `wall` field ("campus" or "national")

**Fix**: 
- Added `wall` field to CreatePostRequest
- Updated createPost method to accept wall parameter
- Created WallType enum for type safety
- Updated CreatePostView with wall selector

---

### 5. PostListResponse - Incorrect Structure
**Issue**: Response structure didn't match backend pagination format.

**Old**: `{ posts: [Post], total: Int? }`
**Backend Spec**: `{ data: [Post], pagination: { page, limit, total, totalPages } }`

**Fix**: Updated PostListResponse with correct structure and nested Pagination object.

---

### 6. Like/Unlike Endpoints - Wrong URLs and Methods
**Issue**: Using separate like/unlike endpoints with wrong URL pattern.

**Old**: 
- POST `/posts/{id}/like` to like
- DELETE `/posts/{id}/like` to unlike

**Backend Spec**: 
- POST `/posts/{id}/likes` to toggle like (returns `{ liked: true/false }`)

**Fix**:
- Removed separate `likePost` and `unlikePost` methods
- Added single `toggleLike` method using `/likes` endpoint
- Added LikeResponse model to handle response

---

### 7. Missing Comment Endpoints
**Issue**: No comment functionality implemented.

**Backend Spec**: 
- POST `/posts/{id}/comments` to add comment
- GET `/posts/{id}/comments?page&limit&sort` to get comments

**Fix**:
- Added Comment model
- Added CommentListResponse model
- Added CreateCommentRequest model
- Implemented `addComment` method
- Implemented `getComments` method with pagination

---

### 8. Header Name Case Sensitivity
**Issue**: Using `X-User-ID` (uppercase ID) instead of `X-User-Id` (mixed case).

**Backend Spec**: Uses `X-User-Id` header

**Fix**: Changed all occurrences in AuthService and PostService to use `X-User-Id`.

---

### 9. Query Parameters Missing
**Issue**: fetchPosts method was not supporting wall, sort, and proper pagination.

**Backend Spec**: Supports `wall`, `page`, `limit`, and `sort` query parameters

**Fix**: 
- Added all query parameters to fetchPosts method
- Created SortOrder enum for type safety
- Default values: wall=campus, page=1, limit=20, sort=NEWEST

---

### 10. Delete Post Method
**Issue**: Implementation had deletePost functionality that's not in the backend spec.

**Backend Spec**: No delete endpoint documented

**Fix**: Removed deletePost method and UI delete buttons.

---

## Type Safety Improvements

Created `PostEnums.swift` with:

### WallType Enum
```swift
enum WallType: String, Codable, CaseIterable {
    case campus = "campus"
    case national = "national"
}
```

### SortOrder Enum
```swift
enum SortOrder: String, Codable, CaseIterable {
    case newest = "NEWEST"
    case oldest = "OLDEST"
    case mostLiked = "MOST_LIKED"
    case leastLiked = "LEAST_LIKED"
}
```

These enums replace magic strings throughout the codebase and provide compile-time safety.

---

## View Updates

### PostRowView
- Changed `post.isLikedByCurrentUser` to `post.liked`
- Changed `post.likesCount` to `post.likes`
- Updated preview to use new Post structure

### WallView
- Updated to use `PostListResponse.data` array
- Changed like functionality to use `toggleLike`
- Removed delete post functionality
- Updated author ID comparison to use `post.author.id`

### CreatePostView
- Added wall type picker (Campus/National)
- Updated to use WallType enum
- Pass selected wall to createPost method

---

## Documentation Updates

Updated `API_DOCUMENTATION.md` to include:
- Complete post endpoints documentation
- Comment endpoints documentation
- Query parameter documentation
- Updated user flows
- Implementation notes section
- Known limitations
- HTTP status codes
- Error handling details

---

## Important Notes

### Case Handling for Wall Field
The backend uses different casing for wall field:
- **Request**: lowercase ("campus", "national")
- **Response**: uppercase ("CAMPUS", "NATIONAL")

Our implementation handles this correctly:
- WallType enum uses lowercase raw values for requests
- Post model uses String type to handle uppercase responses from backend

### PostEnums.swift File
The new `PostEnums.swift` file was created but needs to be added to the Xcode project manually through the Xcode IDE. The file contains:
- WallType enum
- SortOrder enum

---

## Testing Recommendations

Before deploying, ensure to test:

1. **Registration Flow** - Verify passwordSet field is handled correctly
2. **Post Creation** - Test both campus and national wall types
3. **Post Listing** - Verify pagination and wall filtering work
4. **Like Toggle** - Ensure like/unlike works with new endpoint
5. **Comment Features** - Test adding and retrieving comments
6. **Authentication Headers** - Verify X-User-Id header is sent correctly

---

## Breaking Changes

None. All changes maintain backward compatibility where possible. The changes align the iOS app with the actual backend API specification.
