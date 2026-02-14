# iOS Engineering Standards & Architecture Guidelines

This document defines the **mandatory engineering standards** for this codebase.  
All generated or modified code must comply with these principles.

The goal is **enterprise-grade, scalable, thread-safe, testable, production-ready architecture**.

---

# 1. Architecture Principles

## 1.1 MVVM Strict Separation

- Views must contain **no business logic**
- ViewModels must contain **no UI layout logic**
- Services must contain **no UI or SwiftUI dependencies**
- Networking must be abstracted behind protocols
- Dependency injection must be used for services

### Never:
- Put networking code in a View
- Put state mutation inside SwiftUI view builders
- Access UserDefaults directly inside Views

---

# 2. Concurrency & Thread Safety

## 2.1 Main Thread Rules

- All ViewModels must be annotated with `@MainActor`
- UI state updates must occur on MainActor
- No manual `DispatchQueue.main.async`

## 2.2 Structured Concurrency Only

- Use `async/await`
- No completion-handler based APIs
- No callback pyramids
- No unstructured `Task {}` without lifecycle management

## 2.3 Task Lifecycle Management

- Long-running tasks must be cancellable
- Store `Task` references when appropriate
- Cancel tasks in `deinit` or lifecycle events

## 2.4 No Shared Mutable State

- Use `actor` for shared mutable resources
- Avoid global mutable state
- Avoid static mutable singletons unless actor-isolated

---

# 3. Networking Standards

## 3.1 Centralized Request Building

- All URLRequest creation must go through a Request Builder
- No duplicated header setup
- No hardcoded header strings in multiple files

## 3.2 Error Handling

- Map backend errors into domain-specific error types
- Never expose raw networking errors to UI
- Handle 401/403 globally
- Retry only idempotent requests

## 3.3 Retry Policy

- Implement exponential backoff for transient failures
- Do NOT retry client errors (4xx)
- Must respect cancellation

---

# 4. State Management

## 4.1 Observable State

- Use `@Published` inside ViewModels
- Avoid nested observable objects when possible
- Avoid unnecessary bindings in SwiftUI

## 4.2 Pagination

- Pagination logic must be reusable
- No duplicated page counters across ViewModels
- Encapsulate pagination state

---

# 5. Persistence Rules

## 5.1 Thread Safety

- No direct `UserDefaults.standard` access outside a dedicated abstraction
- Wrap persistence in an `actor`

## 5.2 Security

- Tokens must be stored in Keychain
- Never log sensitive data
- No tokens in debug print statements

---

# 6. SwiftUI Best Practices

## 6.1 View Simplicity

- Views must remain declarative
- Extract complex subviews
- Avoid 200+ line Views

## 6.2 Bindings

- Avoid `ForEach($array)` unless mutation is required
- Prefer immutable models passed down

## 6.3 Performance

- Avoid unnecessary view recomputation
- Use `@StateObject` correctly
- Avoid expensive work in `body`

---

# 7. Accessibility

- All interactive elements must include:
  - `.accessibilityLabel`
  - `.accessibilityHint` when appropriate
- Support Dynamic Type
- Avoid fixed font sizes unless justified

---

# 8. Testing Standards

## 8.1 Required Coverage

Must include tests for:
- Async flows
- Error mapping
- Retry logic
- Pagination edge cases
- Cancellation

## 8.2 Testable Design

- Services must be protocol-based
- ViewModels must allow dependency injection
- No hardcoded singletons

---

# 9. Code Quality Rules

## 9.1 Avoid

- Force unwraps
- Force casts
- Magic strings
- Duplicated logic
- Massive ViewModels
- Massive network managers

## 9.2 Prefer

- Small focused types
- Composition over inheritance
- Clear domain modeling
- Immutable structs
- Explicit access control

---

# 10. Production Readiness Checklist

Every new feature must:

- Be thread-safe
- Be cancellation-safe
- Avoid duplication
- Follow MVVM separation
- Handle failure cases
- Not introduce UI blocking
- Not introduce global mutable state
- Be testable

---

# 11. Refactoring Expectations

When modifying code:

- Improve structure if possible
- Reduce duplication
- Do not introduce regressions
- Preserve behavior
- Maintain readability

---

# 12. Performance Requirements

- No blocking calls on main thread
- No synchronous network calls
- No heavy computation inside SwiftUI body
- Measure before optimizing

---

# 13. Documentation Standard

Complex logic must include:
- Short explanation of intent
- Reason for architectural choice if non-obvious

Avoid over-commenting obvious code.

---

# 14. Definition of Done

Code is not complete unless:

- It compiles without warnings
- It passes all tests
- It follows this document
- It introduces no architectural regression

---

# Core Philosophy

This project follows:

- Modern Swift
- Structured concurrency
- MVVM
- Protocol-oriented design
- Thread safety by default
- Scalability first
- Clean architecture mindset

All generated code must reflect senior-level iOS engineering standards.



## API Documentation

### Common Response Codes

- `200 OK` - Request successful
- `201 Created` - Resource created successfully
- `400 Bad Request` - Invalid request parameters or validation failed
- `401 Unauthorized` - Missing or invalid authentication token
- `403 Forbidden` - Access denied (insufficient permissions or blocked user)
- `404 Not Found` - Resource not found
- `500 Internal Server Error` - Server error

**Blocked User Response:**
When a blocked user attempts any authenticated operation, they receive:
```json
HTTP/1.1 403 Forbidden
Content-Type: application/json

{
    "error": "Access denied. Your account has been blocked."
}
```

### Authentication Endpoints

#### 1. Send Email Verification Code
```http
POST /api/v1/auth/email/send-code
Content-Type: application/json

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

{
    "email": "student@harvard.edu",
    "code": "123456"
}

Response: 201 Created
{
    "user": {
        "id": "uuid",
        "email": "student@harvard.edu",
        "profileName": "Anonymous",
        "isVerified": true,
        "passwordSet": false,
        "createdAt": "2026-01-28T..."
    },
    "accessToken": "jwt-token-here"
}
```

#### 3. Login with Email Code
```http
POST /api/v1/auth/login/email
Content-Type: application/json

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

{
    "password": "secure_password"
}

Response: 200 OK
{
    "id": "uuid",
    "email": "student@harvard.edu",
    "profileName": "Anonymous",
    "isVerified": true,
    "passwordSet": true,
    "createdAt": "2026-01-28T..."
}
```

#### 6. Change Password (Requires Authentication)
```http
POST /api/v1/auth/password/change
Authorization: Bearer {jwt-token}
Content-Type: application/json

{
    "oldPassword": "current_password",
    "newPassword": "new_password"
}

Response: 200 OK
{
    "id": "uuid",
    "email": "student@harvard.edu",
    "profileName": "Anonymous",
    "isVerified": true,
    "passwordSet": true,
    "createdAt": "2026-01-28T..."
}
```

#### 7. Request Password Reset (Forgot Password)
```http
POST /api/v1/auth/password/reset-request
Content-Type: application/json

{
    "email": "student@harvard.edu"
}

Response: 200 OK
{
    "message": "Password reset code sent to email"
}
```

**Notes:**
- Sends a 6-digit verification code to the user's email
- User must provide this code to reset their password
- Code expires after 15 minutes

#### 8. Reset Password
```http
POST /api/v1/auth/password/reset
Content-Type: application/json

{
    "email": "student@harvard.edu",
    "code": "123456",
    "newPassword": "new_password"
}

Response: 200 OK
{
    "user": {
        "id": "uuid",
        "email": "student@harvard.edu",
        "profileName": "Anonymous",
        "isVerified": true,
        "passwordSet": true,
        "createdAt": "2026-01-28T..."
    },
    "accessToken": "jwt-token-here"
}
```

**Notes:**
- Requires valid email verification code
- Code must not be expired (15 minute expiration)
- Returns JWT token upon successful password reset

---

### Post Endpoints

#### 1. Create Post
```http
POST /api/v1/posts
Authorization: Bearer {jwt-token}
Content-Type: application/json

{
    "title": "My First Post Title",    // NEW - REQUIRED (1-255 chars)
    "content": "This is my first post!",
    "wall": "campus"  // or "national", optional, defaults to "campus"
}

Response: 201 Created
{
    "id": "uuid",
    "title": "My First Post Title",     // NEW
    "content": "This is my first post!",
    "wall": "CAMPUS",
    "likes": 0,
    "comments": 0,
    "liked": false,
    "author": {
        "id": "uuid",
        "profileName": "Anonymous",
        "isAnonymous": true
    },
    "createdAt": "2026-01-28T...",
    "updatedAt": "2026-01-28T..."
}
```

**Request Validation:**
- `title` is **required** (cannot be null, empty, or whitespace-only)
- `title` maximum length: **255 characters**
- `content` is **required** (cannot be null, empty, or whitespace-only)
- `content` maximum length: **5000 characters**
- `wall` is optional (defaults to "campus"), must be "campus" or "national"

**Error Responses:**
```json
// Missing or empty title
400 Bad Request
{
    "error": "Post title cannot be empty"
}

// Title exceeds 255 characters
400 Bad Request
{
    "error": "Post title exceeds maximum length of 255 characters"
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
            "id": "uuid",
            "title": "Post Title",        // NEW
            "content": "Post content",
            "wall": "CAMPUS",
            "likes": 5,
            "comments": 2,
            "liked": false,
            "author": {
                "id": "uuid",
                "profileName": "John Doe",
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
- `sort` (default: "NEWEST") - Sort order: NEWEST, OLDEST, MOST_LIKED, LEAST_LIKED, MOST_COMMENTED, LEAST_COMMENTED

#### 3. Get Post by ID
```http
GET /api/v1/posts/{postId}
Authorization: Bearer {jwt-token}

Response: 200 OK
{
    "id": "uuid",
    "title": "Post Title",
    "content": "Post content",
    "wall": "CAMPUS",
    "likes": 5,
    "comments": 2,
    "liked": false,
    "author": {
        "id": "uuid",
        "profileName": "John Doe",
        "isAnonymous": true
    },
    "createdAt": "2026-01-28T...",
    "updatedAt": "2026-01-28T..."
}

Response: 404 Not Found
{
    "error": "Post not found"
}

Response: 403 Forbidden
{
    "error": "You do not have access to posts from other schools"
}
```

**Notes:**
- Retrieves a single post by its ID
- For campus posts: only users from the same school can access
- For national posts: all authenticated users can access
- Returns 404 if post does not exist
- Returns 403 if user doesn't have access to the post

#### 4. Like/Unlike Post (Toggle)
```http
POST /api/v1/posts/{postId}/likes
Authorization: Bearer {jwt-token}

Response: 200 OK
{
    "liked": true,
    "likeCount": 6
}
```

**Notes:**
- Single endpoint that toggles like state (like if not liked, unlike if already liked)
- Returns both the new like state and total like count for the post
- For campus posts: only users from the same school can like
- For national posts: all authenticated users can like
- Response: `liked` (boolean) indicates post is now liked, `likeCount` is total likes on post


#### 5. Add Comment
```http
POST /api/v1/posts/{postId}/comments
Authorization: Bearer {jwt-token}
Content-Type: application/json

{
    "text": "Great post!"
}

Response: 201 Created
{
    "id": "uuid",
    "postId": "uuid",
    "text": "Great post!",
    "author": {
        "id": "uuid",
        "profileName": "Anonymous",
        "isAnonymous": true
    },
    "createdAt": "2026-01-28T..."
}

Response: 400 Bad Request
{
    "error": "Comment text cannot be empty"
}

Response: 400 Bad Request
{
    "error": "Comment text exceeds maximum length of 5000 characters"
}
```

**Validation Rules:**
- `text` is **required** (cannot be null, empty, or whitespace-only)
- `text` maximum length: **5000 characters**

#### 6. Get Comments for Post
```http
GET /api/v1/posts/{postId}/comments?page=1&limit=20&sort=NEWEST
Authorization: Bearer {jwt-token}

Response: 200 OK
{
    "data": [
        {
            "id": "uuid",
            "postId": "uuid",
            "text": "Great post!",
            "author": {
                "id": "uuid",
                "profileName": "Jane Smith",
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

#### 7. Hide Post
```http
PATCH /api/v1/posts/{postId}/hide
Authorization: Bearer {jwt-token}

Response: 200 OK
{
    "message": "Post hidden successfully"
}
```

**Notes:**
- Only the post author can hide their own post
- When a post is hidden, all its comments are also hidden
- This is a soft-delete operation; data is preserved in the database

#### 8. Unhide Post
```http
PATCH /api/v1/posts/{postId}/unhide
Authorization: Bearer {jwt-token}

Response: 200 OK
{
    "message": "Post unhidden successfully"
}
```

**Notes:**
- Only the post author can unhide their own post
- When a post is unhidden, all its previously hidden comments are also restored


#### 9. Hide Comment
```http
PATCH /api/v1/posts/{postId}/comments/{commentId}/hide
Authorization: Bearer {jwt-token}

Response: 200 OK
{
    "message": "Comment hidden successfully"
}
```

**Notes:**
- Only the comment author can hide their own comment
- This is a soft-delete operation; data is preserved in the database

#### 10. Unhide Comment
```http
PATCH /api/v1/posts/{postId}/comments/{commentId}/unhide
Authorization: Bearer {jwt-token}

Response: 200 OK
{
    "message": "Comment unhidden successfully"
}
```

**Notes:**
- Only the comment author can unhide their own comment

#### 11. Report Post
```http
POST /api/v1/posts/{postId}/reports
Authorization: Bearer {jwt-token}
Content-Type: application/json

{
    "reason": "This post contains inappropriate content"
}

Response: 201 Created
{
    "message": "Post reported successfully"
}
```

**Notes:**
- A user can only report the same post once
- `reason` is optional (max length: 500 characters)
- Reporting a post increments the report count for the post author
- Duplicate reports by the same user will return: `400 Bad Request`

#### 12. Report Comment
```http
POST /api/v1/posts/{postId}/comments/{commentId}/reports
Authorization: Bearer {jwt-token}
Content-Type: application/json

{
    "reason": "This comment violates community guidelines"
}

Response: 201 Created
{
    "message": "Comment reported successfully"
}
```

**Notes:**
- A user can only report the same comment once
- `reason` is optional (max length: 500 characters)
- Reporting a comment increments the report count for the comment author
- Duplicate reports by the same user will return: `400 Bad Request`

### User Endpoints

#### 1. Get User's Own Comments
```http
GET /api/v1/users/me/comments?page=1&limit=20&sort=NEWEST
Authorization: Bearer {jwt-token}

Response: 200 OK
{
    "data": [
        {
            "id": "uuid",
            "postId": "uuid",
            "text": "Great post!",
            "author": {
                "id": "uuid",
                "profileName": "Jane Smith",
                "isAnonymous": true
            },
            "createdAt": "2026-01-28T..."
        }
    ],
    "pagination": {
        "page": 1,
        "limit": 20,
        "total": 50,
        "totalPages": 3
    }
}
```

**Query Parameters:**
- `page` (default: 1) - Page number (1-based)
- `limit` (default: 20) - Comments per page (max: 100)
- `sort` (default: "NEWEST") - Sort order: NEWEST, OLDEST

**Notes:**
- Returns all comments made by the authenticated user across all posts
- Hidden (soft-deleted) comments are automatically excluded
- Uses optimized query with composite database index for efficient retrieval
- Performance: O(log K) where K is the user's total comment count

#### 2. Get User's Own Posts
```http
GET /api/v1/users/me/posts?page=1&limit=20&sort=NEWEST
Authorization: Bearer {jwt-token}

Response: 200 OK
{
    "data": [
        {
            "id": "uuid",
            "title": "My Post Title",
            "content": "Post content here...",
            "wall": "campus",
            "likes": 42,
            "comments": 15,
            "liked": false,
            "author": {
                "id": "uuid",
                "profileName": "John Doe",
                "isAnonymous": true
            },
            "createdAt": "2026-01-28T...",
            "updatedAt": "2026-01-28T..."
        }
    ],
    "pagination": {
        "page": 1,
        "limit": 20,
        "total": 100,
        "totalPages": 5
    }
}
```

**Query Parameters:**
- `page` (default: 1) - Page number (1-based)
- `limit` (default: 20) - Posts per page (max: 100)
- `sort` (default: "NEWEST") - Sort order: NEWEST, OLDEST, MOST_LIKED, LEAST_LIKED, MOST_COMMENTED, LEAST_COMMENTED

**Notes:**
- Returns all posts created by the authenticated user
- Hidden (soft-deleted) posts are automatically excluded
- Uses optimized queries with composite database indexes for efficient retrieval
- Performance: O(log K) where K is the user's total post count
- Supports sorting by creation time, like count, or comment count

#### 3. Update Profile Name (Requires Authentication)
```http
PATCH /api/v1/users/me/profile/name
Authorization: Bearer {jwt-token}
Content-Type: application/json

{
    "profileName": "John Doe"
}

Response: 200 OK
{
    "id": "uuid",
    "email": "student@harvard.edu",
    "profileName": "John Doe",
    "isVerified": true,
    "passwordSet": false,
    "createdAt": "2026-01-28T..."
}
```

**Notes:**
- Default profile name is "Anonymous"
- Sending an empty string will reset the profile name to "Anonymous"
- Profile name can be 1-255 characters
- Profile name changes are **asynchronously propagated** to all user's posts and comments
- The API returns immediately after updating the user profile
- Posts and comments are updated in the background for better performance
