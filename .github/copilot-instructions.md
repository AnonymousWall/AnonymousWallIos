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
    "parentType": "POST",
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
            "parentType": "POST",
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

### Internship Endpoints

#### 1. Create Internship Posting
```http
POST /api/v1/internships
Authorization: Bearer {jwt-token}
Content-Type: application/json

{
    "company": "Google",
    "role": "Software Engineer Intern",
    "salary": "$8000/month",
    "location": "Mountain View, CA",
    "description": "Work on cutting-edge projects with experienced mentors",
    "deadline": "2026-06-30",
    "wall": "campus"
}

Response: 201 Created
{
    "id": "uuid",
    "company": "Google",
    "role": "Software Engineer Intern",
    "salary": "$8000/month",
    "location": "Mountain View, CA",
    "description": "Work on cutting-edge projects with experienced mentors",
    "deadline": "2026-06-30",
    "wall": "CAMPUS",
    "comments": 0,
    "author": {
        "id": "uuid",
        "profileName": "John Recruiter",
        "isAnonymous": false
    },
    "createdAt": "2026-02-18T...",
    "updatedAt": "2026-02-18T..."
}
```

**Request Validation:**
- `company` is **required** (cannot be null, empty, or whitespace-only)
- `company` maximum length: **255 characters**
- `role` is **required** (cannot be null, empty, or whitespace-only)
- `role` maximum length: **255 characters**
- `salary` is optional (VARCHAR(50))
- `location` is optional (VARCHAR(255))
- `description` is optional (TEXT)
- `deadline` is optional (DATE format: YYYY-MM-DD, defaults to 1 month from creation date)
- `wall` is optional (defaults to "campus"), must be "campus" or "national"

**Wall Rules:**
- **Campus wall**: Only users from the same school can see the posting
- **National wall**: All authenticated users can see the posting

**Error Responses:**
```json
// Missing or empty company
400 Bad Request
{
    "error": "Company is required"
}

// Company exceeds 255 characters
400 Bad Request
{
    "error": "Company name cannot exceed 255 characters"
}

// Missing or empty role
400 Bad Request
{
    "error": "Role is required"
}

// Role exceeds 255 characters
400 Bad Request
{
    "error": "Role cannot exceed 255 characters"
}

// User not found
400 Bad Request
{
    "error": "User not found"
}
```

#### 2. List Internship Postings
```http
GET /api/v1/internships?wall=campus&page=1&limit=20&sortBy=newest
Authorization: Bearer {jwt-token}

Response: 200 OK
{
    "data": [
        {
            "id": "uuid",
            "company": "Google",
            "role": "Software Engineer Intern",
            "salary": "$8000/month",
            "location": "Mountain View, CA",
            "description": "Work on cutting-edge projects with experienced mentors",
            "deadline": "2026-06-30",
            "wall": "CAMPUS",
            "comments": 3,
            "author": {
                "id": "uuid",
                "profileName": "John Recruiter",
                "isAnonymous": false
            },
            "createdAt": "2026-02-18T...",
            "updatedAt": "2026-02-18T..."
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
- `wall` (default: "campus") - Filter by "campus" or "national"
- `page` (default: 1): Page number for pagination (1-based indexing)
- `limit` (default: 20): Number of items per page (min: 1, max: 100)
- `sortBy` (default: newest): Sort order - "newest" (newest first) or "oldest" (oldest first)

**Wall Rules:**
- **Campus**: Returns only internships from the same school as the authenticated user
- **National**: Returns all national internships
- Only non-hidden internships are returned

#### 3. Get Internship Posting by ID
```http
GET /api/v1/internships/{internshipId}
Authorization: Bearer {jwt-token}

Response: 200 OK
{
    "id": "uuid",
    "company": "Google",
    "role": "Software Engineer Intern",
    "salary": "$8000/month",
    "location": "Mountain View, CA",
    "description": "Work on cutting-edge projects with experienced mentors",
    "deadline": "2026-06-30",
    "wall": "CAMPUS",
    "comments": 3,
    "author": {
        "id": "uuid",
        "profileName": "John Recruiter",
        "isAnonymous": false
    },
    "createdAt": "2026-02-18T...",
    "updatedAt": "2026-02-18T..."
}
```

**Error Responses:**
```json
// Internship not found
404 Not Found

// Campus internship from different school
403 Forbidden
{
    "error": "You do not have access to internships from other schools"
}
```

#### 4. Hide Internship Posting
```http
PATCH /api/v1/internships/{internshipId}/hide
Authorization: Bearer {jwt-token}

Response: 200 OK
{
    "message": "Internship posting hidden successfully"
}
```

**Notes:**
- Only the author can hide their own internship posting
- Hidden internships are excluded from list results
- Soft-delete operation (data is not permanently removed)

**Error Responses:**
```json
// Not the author
403 Forbidden
{
    "error": "You can only hide your own internship postings"
}

// Internship not found
404 Not Found
```

#### 5. Unhide Internship Posting
```http
PATCH /api/v1/internships/{internshipId}/unhide
Authorization: Bearer {jwt-token}

Response: 200 OK
{
    "message": "Internship posting unhidden successfully"
}
```

**Notes:**
- Only the author can unhide their own internship posting
- Unhidden internships reappear in list results

**Error Responses:**
```json
// Not the author
403 Forbidden
{
    "error": "You can only unhide your own internship postings"
}

// Internship not found
404 Not Found
```

#### 6. Add Comment to Internship
```http
POST /api/v1/internships/{internshipId}/comments
Authorization: Bearer {jwt-token}
Content-Type: application/json

{
    "text": "Great opportunity!"
}

Response: 201 Created
{
    "id": "uuid",
    "postId": "uuid",
    "parentType": "INTERNSHIP",
    "text": "Great opportunity!",
    "author": {
        "id": "uuid",
        "profileName": "Anonymous",
        "isAnonymous": true
    },
    "createdAt": "2026-02-18T..."
}
```

**Validation Rules:**
- `text` is **required** (cannot be null, empty, or whitespace-only)
- `text` maximum length: **5000 characters**
- For campus internships: only users from the same school can comment
- For national internships: all authenticated users can comment

#### 7. Get Comments for Internship
```http
GET /api/v1/internships/{internshipId}/comments?page=1&limit=20&sort=NEWEST
Authorization: Bearer {jwt-token}

Response: 200 OK
{
    "data": [
        {
            "id": "uuid",
            "postId": "uuid",
            "parentType": "INTERNSHIP",
            "text": "Great opportunity!",
            "author": {
                "id": "uuid",
                "profileName": "Jane Smith",
                "isAnonymous": true
            },
            "createdAt": "2026-02-18T..."
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

#### 8. Hide Comment on Internship
```http
PATCH /api/v1/internships/{internshipId}/comments/{commentId}/hide
Authorization: Bearer {jwt-token}

Response: 200 OK
{
    "message": "Comment hidden successfully"
}
```

**Notes:**
- Only the comment author can hide their own comment

#### 9. Unhide Comment on Internship
```http
PATCH /api/v1/internships/{internshipId}/comments/{commentId}/unhide
Authorization: Bearer {jwt-token}

Response: 200 OK
{
    "message": "Comment unhidden successfully"
}
```

**Notes:**
- Only the comment author can unhide their own comment

### Marketplace Endpoints

#### 1. Create Marketplace Item
```http
POST /api/v1/marketplace
Authorization: Bearer {jwt-token}
Content-Type: application/json

{
    "title": "Used Calculus Textbook",
    "price": 45.99,
    "description": "Barely used, excellent condition",
    "category": "books",
    "condition": "like_new",
    "contactInfo": "johndoe@harvard.edu",
    "wall": "campus"
}

Response: 201 Created
{
    "id": "uuid",
    "title": "Used Calculus Textbook",
    "price": 45.99,
    "description": "Barely used, excellent condition",
    "category": "books",
    "condition": "like_new",
    "contactInfo": "johndoe@harvard.edu",
    "sold": false,
    "wall": "CAMPUS",
    "comments": 0,
    "author": {
        "id": "uuid",
        "profileName": "John Doe",
        "isAnonymous": false
    },
    "createdAt": "2026-02-18T...",
    "updatedAt": "2026-02-18T..."
}
```

**Request Validation:**
- `title` is **required** (cannot be null, empty, or whitespace-only)
- `title` maximum length: **255 characters**
- `price` is **required** and must be **≥ 0**
- `price` maximum value: **99,999,999.99** (DECIMAL(10,2))
- `description` is optional (max length: 5000 characters)
- `category` is optional
- `condition` is optional, valid values: "new", "like_new", "good", "fair", "poor"
- `contactInfo` is optional
- `wall` is optional (defaults to "campus"), must be "campus" or "national"

**Wall Rules:**
- **Campus wall**: Only users from the same school can see the item
- **National wall**: All authenticated users can see the item

**Error Responses:**
```json
// Missing or empty title
400 Bad Request
{
    "error": "Title cannot be empty"
}

// Title exceeds 255 characters
400 Bad Request
{
    "error": "Title cannot exceed 255 characters"
}

// Missing or invalid price
400 Bad Request
{
    "error": "Price is required"
}

// Negative price
400 Bad Request
{
    "error": "Price must be greater than or equal to 0"
}

// Invalid condition
400 Bad Request
{
    "error": "Invalid condition. Must be one of: new, like_new, good, fair, poor"
}
```

#### 2. List Marketplace Items
```http
GET /api/v1/marketplace?wall=campus&page=1&limit=20&sortBy=newest&sold=false
Authorization: Bearer {jwt-token}

Response: 200 OK
{
    "data": [
        {
            "id": "uuid",
            "title": "Used Calculus Textbook",
            "price": 45.99,
            "description": "Barely used, excellent condition",
            "category": "books",
            "condition": "like_new",
            "contactInfo": "johndoe@harvard.edu",
            "sold": false,
            "wall": "CAMPUS",
            "comments": 2,
            "author": {
                "id": "uuid",
                "profileName": "John Doe",
                "isAnonymous": false
            },
            "createdAt": "2026-02-18T...",
            "updatedAt": "2026-02-18T..."
        }
    ],
    "pagination": {
        "page": 1,
        "limit": 20,
        "total": 95,
        "totalPages": 5
    }
}
```

**Query Parameters:**
- `wall` (default: "campus") - Filter by "campus" or "national"
- `page` (default: 1) - Page number (1-based)
- `limit` (default: 20) - Items per page (max: 100)
- `sortBy` (default: "newest") - Sort order:
  - `newest` - Sort by creation date descending (newest first)
  - `price-asc` - Sort by price ascending (lowest first)
  - `price-desc` - Sort by price descending (highest first)
- `sold` (optional) - Filter by sold status:
  - `true` - Show only sold items
  - `false` - Show only unsold items
  - omit parameter - Show all items (both sold and unsold)

**Wall Rules:**
- **Campus**: Returns only items from the same school as the authenticated user
- **National**: Returns all national items

**Examples:**
```http
GET /api/v1/marketplace?wall=campus&sold=false&sortBy=price-asc
GET /api/v1/marketplace?wall=national&sold=true&page=1&limit=10
GET /api/v1/marketplace?sortBy=newest
```

#### 3. Get Marketplace Item by ID
```http
GET /api/v1/marketplace/{itemId}
Authorization: Bearer {jwt-token}

Response: 200 OK
{
    "id": "uuid",
    "title": "Used Calculus Textbook",
    "price": 45.99,
    "description": "Barely used, excellent condition",
    "category": "books",
    "condition": "like_new",
    "contactInfo": "johndoe@harvard.edu",
    "sold": false,
    "wall": "CAMPUS",
    "comments": 2,
    "author": {
        "id": "uuid",
        "profileName": "John Doe",
        "isAnonymous": false
    },
    "createdAt": "2026-02-18T...",
    "updatedAt": "2026-02-18T..."
}

Response: 404 Not Found
{
    "error": "Item not found"
}
```

**Notes:**
- For campus items: only users from the same school can access
- For national items: all authenticated users can access

#### 4. Update Marketplace Item (Partial Update)
```http
PUT /api/v1/marketplace/{itemId}
Authorization: Bearer {jwt-token}
Content-Type: application/json

{
    "title": "Used Calculus Textbook - Price Reduced",
    "price": 35.99,
    "sold": true
}

Response: 200 OK
{
    "id": "uuid",
    "title": "Used Calculus Textbook - Price Reduced",
    "price": 35.99,
    "description": "Barely used, excellent condition",
    "category": "books",
    "condition": "like_new",
    "contactInfo": "johndoe@harvard.edu",
    "sold": true,
    "wall": "CAMPUS",
    "comments": 2,
    "author": {
        "id": "uuid",
        "profileName": "John Doe",
        "isAnonymous": false
    },
    "createdAt": "2026-02-18T...",
    "updatedAt": "2026-02-18T..."
}
```

**Partial Update Behavior:**
- All fields are **optional** in the update request
- Only provided fields will be updated
- Fields not included in the request remain unchanged
- Null-safe: setting a field to null will not update it

**Updatable Fields:**
- `title` (max 255 characters, cannot be empty/whitespace-only)
- `price` (must be ≥ 0 if provided)
- `description` (max 5000 characters)
- `category`
- `condition` (must be valid enum value)
- `contactInfo`
- `sold` (boolean - mark item as sold/unsold)

**Ownership Validation:**
- Users can only update their own items
- Attempting to update another user's item returns: `403 Forbidden`

**Error Responses:**
```json
// Attempting to update another user's item
403 Forbidden
{
    "error": "You can only update your own items"
}

// Item not found
404 Not Found
{
    "error": "Item not found"
}

// Negative price
400 Bad Request
{
    "error": "Price must be greater than or equal to 0"
}

// Empty title
400 Bad Request
{
    "error": "Title cannot be empty"
}

// Invalid condition
400 Bad Request
{
    "error": "Invalid condition. Must be one of: new, like_new, good, fair, poor"
}
```

**Update Examples:**
```http
// Mark item as sold
PUT /api/v1/marketplace/{itemId}
{
    "sold": true
}

// Update only price
PUT /api/v1/marketplace/{itemId}
{
    "price": 25.00
}

// Update multiple fields
PUT /api/v1/marketplace/{itemId}
{
    "title": "Updated Title",
    "price": 30.00,
    "description": "Updated description",
    "sold": false
}
```

#### 5. Add Comment to Marketplace Item
```http
POST /api/v1/marketplace/{itemId}/comments
Authorization: Bearer {jwt-token}
Content-Type: application/json

{
    "text": "Is this still available?"
}

Response: 201 Created
{
    "id": "uuid",
    "postId": "uuid",
    "parentType": "MARKETPLACE",
    "text": "Is this still available?",
    "author": {
        "id": "uuid",
        "profileName": "Anonymous",
        "isAnonymous": true
    },
    "createdAt": "2026-02-18T..."
}
```

**Validation Rules:**
- `text` is **required** (cannot be null, empty, or whitespace-only)
- `text` maximum length: **5000 characters**
- For campus items: only users from the same school can comment
- For national items: all authenticated users can comment

#### 6. Get Comments for Marketplace Item
```http
GET /api/v1/marketplace/{itemId}/comments?page=1&limit=20&sort=NEWEST
Authorization: Bearer {jwt-token}

Response: 200 OK
{
    "data": [
        {
            "id": "uuid",
            "postId": "uuid",
            "parentType": "MARKETPLACE",
            "text": "Is this still available?",
            "author": {
                "id": "uuid",
                "profileName": "Jane Smith",
                "isAnonymous": true
            },
            "createdAt": "2026-02-18T..."
        }
    ],
    "pagination": {
        "page": 1,
        "limit": 20,
        "total": 3,
        "totalPages": 1
    }
}
```

**Query Parameters:**
- `page` (default: 1) - Page number (1-based)
- `limit` (default: 20) - Comments per page (max: 100)
- `sort` (default: "NEWEST") - Sort order: NEWEST, OLDEST

#### 7. Hide Comment on Marketplace Item
```http
PATCH /api/v1/marketplace/{itemId}/comments/{commentId}/hide
Authorization: Bearer {jwt-token}

Response: 200 OK
{
    "message": "Comment hidden successfully"
}
```

**Notes:**
- Only the comment author can hide their own comment

#### 8. Unhide Comment on Marketplace Item
```http
PATCH /api/v1/marketplace/{itemId}/comments/{commentId}/unhide
Authorization: Bearer {jwt-token}

Response: 200 OK
{
    "message": "Comment unhidden successfully"
}
```

**Notes:**
- Only the comment author can unhide their own comment

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
            "parentType": "POST",
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
- Returns all comments made by the authenticated user across all entity types (posts, internships, marketplace items)
- Each comment includes `parentType` ("POST", "INTERNSHIP", or "MARKETPLACE") to identify the parent entity
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

#### 3. Get User's Own Internships
```http
GET /api/v1/users/me/internships?page=1&limit=20&sort=NEWEST
Authorization: Bearer {jwt-token}

Response: 200 OK
{
    "data": [
        {
            "id": "uuid",
            "company": "Google",
            "role": "Software Engineer Intern",
            "salary": "$8000/month",
            "location": "Mountain View, CA",
            "description": "Work on cutting-edge projects",
            "deadline": "2026-06-30",
            "wall": "campus",
            "comments": 3,
            "author": {
                "id": "uuid",
                "profileName": "Jane Smith",
                "isAnonymous": false
            },
            "createdAt": "2026-01-28T...",
            "updatedAt": "2026-01-28T..."
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
- `limit` (default: 20) - Internships per page (max: 100)
- `sort` (default: "NEWEST") - Sort order: NEWEST, OLDEST

**Notes:**
- Returns all internship postings created by the authenticated user
- Hidden (soft-deleted) internships are automatically excluded

#### 4. Get User's Own Marketplace Items
```http
GET /api/v1/users/me/marketplaces?page=1&limit=20&sort=NEWEST
Authorization: Bearer {jwt-token}

Response: 200 OK
{
    "data": [
        {
            "id": "uuid",
            "title": "MacBook Pro 2023",
            "description": "Excellent condition, barely used",
            "price": 1200.0,
            "category": "electronics",
            "condition": "like-new",
            "sold": false,
            "wall": "campus",
            "comments": 2,
            "author": {
                "id": "uuid",
                "profileName": "John Doe",
                "isAnonymous": false
            },
            "createdAt": "2026-01-28T...",
            "updatedAt": "2026-01-28T..."
        }
    ],
    "pagination": {
        "page": 1,
        "limit": 20,
        "total": 10,
        "totalPages": 1
    }
}
```

**Query Parameters:**
- `page` (default: 1) - Page number (1-based)
- `limit` (default: 20) - Items per page (max: 100)
- `sort` (default: "NEWEST") - Sort order: NEWEST, OLDEST

**Notes:**
- Returns all marketplace items listed by the authenticated user
- Hidden (soft-deleted) items are automatically excluded

#### 5. Update Profile Name (Requires Authentication)
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
- Profile name changes are **asynchronously propagated** to all user's posts, comments, internships, and marketplace items
- The API returns immediately after updating the user profile
- Posts, comments, internships, and marketplace items are updated in the background for better performance

---

## Chat API Documentation

### Overview

The Chat API provides **one-to-one messaging** capabilities with both REST endpoints and real-time WebSocket support. Users can send direct messages to other users (except blocked users), view conversation history, and receive real-time notifications.

### Features

✅ **Real-time messaging** via WebSocket  
✅ **Message persistence** in database  
✅ **Blocked user enforcement** (cannot send/receive from blocked users)  
✅ **Read receipts** and unread message counts  
✅ **Conversation list** with last message preview  
✅ **Message history** with pagination  
✅ **WebSocket authentication** with JWT  
✅ **Session management** and automatic reconnection support  

### REST Endpoints

#### 1. Send Message
```http
POST /api/v1/chat/messages
Authorization: Bearer {jwt-token}
Content-Type: application/json

{
  "receiverId": "uuid-of-receiver",
  "content": "Hello! This is a test message."
}

Response: 201 Created
{
  "id": "message-uuid",
  "senderId": "sender-uuid",
  "receiverId": "receiver-uuid",
  "content": "Hello! This is a test message.",
  "readStatus": false,
  "createdAt": "2026-02-14T08:00:00Z"
}
```

**Validations:**
- Message content: 1-5000 characters
- Receiver must exist and not be blocked
- Sender must not be blocked

#### 2. Get Message History
```http
GET /api/v1/chat/messages/{otherUserId}?page=1&limit=50
Authorization: Bearer {jwt-token}

Response: 200 OK
{
  "messages": [
    {
      "id": "message-uuid",
      "senderId": "user1-uuid",
      "receiverId": "user2-uuid",
      "content": "First message",
      "readStatus": true,
      "createdAt": "2026-02-14T07:00:00Z"
    },
    {
      "id": "message-uuid-2",
      "senderId": "user2-uuid",
      "receiverId": "user1-uuid",
      "content": "Reply message",
      "readStatus": false,
      "createdAt": "2026-02-14T07:01:00Z"
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 50,
    "total": 2,
    "totalPages": 1
  }
}
```

**Notes:**
- Messages are returned in chronological order (oldest first)
- Default page size: 50 messages
- Maximum page size: 100 messages

#### 3. Get Conversations
```http
GET /api/v1/chat/conversations
Authorization: Bearer {jwt-token}

Response: 200 OK
{
  "conversations": [
    {
      "userId": "other-user-uuid",
      "profileName": "John Doe",
      "lastMessage": {
        "id": "message-uuid",
        "senderId": "other-user-uuid",
        "receiverId": "current-user-uuid",
        "content": "Last message in conversation",
        "readStatus": false,
        "createdAt": "2026-02-14T08:00:00Z"
      },
      "unreadCount": 3
    }
  ]
}
```

**Notes:**
- Conversations are sorted by last message timestamp (most recent first)
- Only includes conversations with at least one message
- Shows unread message count from each user

#### 4. Mark Message as Read
```http
PUT /api/v1/chat/messages/{messageId}/read
Authorization: Bearer {jwt-token}

Response: 200 OK
{
  "message": "Message marked as read"
}
```

**Access:** Only the message receiver can mark a message as read

#### 5. Mark Conversation as Read
```http
PUT /api/v1/chat/conversations/{otherUserId}/read
Authorization: Bearer {jwt-token}

Response: 200 OK
{
  "message": "Conversation marked as read"
}
```

**Effect:** Marks all messages from the specified user as read

### WebSocket Connection

#### Connection URL
```
ws://localhost:8080/ws/chat
```

#### Authentication
WebSocket connections require JWT authentication via query parameter or header:

**Option 1: Query Parameter**
```javascript
const ws = new WebSocket(`ws://localhost:8080/ws/chat?token=${jwtToken}`);
```

**Option 2: Sec-WebSocket-Protocol Header** (Recommended)
```javascript
const ws = new WebSocket('ws://localhost:8080/ws/chat', ['access_token', jwtToken]);
```

#### Message Format

**Client to Server Messages:**

1. **Send Message**
```json
{
  "type": "message",
  "receiverId": "uuid-of-receiver",
  "content": "Message content"
}
```

2. **Typing Indicator**
```json
{
  "type": "typing",
  "receiverId": "uuid-of-receiver"
}
```

3. **Mark as Read**
```json
{
  "type": "mark_read",
  "messageId": "uuid-of-message"
}
```

**Server to Client Messages:**

1. **Connection Established**
```json
{
  "type": "connected",
  "userId": "your-user-id",
  "timestamp": 1707900000000
}
```

2. **Unread Count**
```json
{
  "type": "unread_count",
  "count": 5
}
```

3. **New Message**
```json
{
  "type": "message",
  "message": {
    "id": "message-uuid",
    "senderId": "sender-uuid",
    "receiverId": "receiver-uuid",
    "content": "Message content",
    "readStatus": false,
    "createdAt": "2026-02-14T08:00:00Z"
  }
}
```

4. **Typing Indicator**
```json
{
  "type": "typing",
  "senderId": "user-uuid"
}
```

5. **Read Receipt**
```json
{
  "type": "read_receipt",
  "messageId": "message-uuid"
}
```

6. **Error**
```json
{
  "type": "error",
  "error": "Error message"
}
```

### JavaScript WebSocket Example

```javascript
// Establish connection
const token = 'your-jwt-token';
const ws = new WebSocket('ws://localhost:8080/ws/chat', ['access_token', token]);

// Connection opened
ws.onopen = (event) => {
  console.log('Connected to chat WebSocket');
};

// Receive messages
ws.onmessage = (event) => {
  const data = JSON.parse(event.data);
  
  switch (data.type) {
    case 'connected':
      console.log('Connection confirmed, user ID:', data.userId);
      break;
      
    case 'message':
      console.log('New message:', data.message);
      displayMessage(data.message);
      break;
      
    case 'typing':
      console.log('User is typing:', data.senderId);
      showTypingIndicator(data.senderId);
      break;
      
    case 'unread_count':
      console.log('Unread messages:', data.count);
      updateUnreadBadge(data.count);
      break;
      
    case 'error':
      console.error('Error:', data.error);
      break;
  }
};

// Send a message
function sendMessage(receiverId, content) {
  ws.send(JSON.stringify({
    type: 'message',
    receiverId: receiverId,
    content: content
  }));
}

// Send typing indicator
function sendTypingIndicator(receiverId) {
  ws.send(JSON.stringify({
    type: 'typing',
    receiverId: receiverId
  }));
}

// Mark message as read
function markAsRead(messageId) {
  ws.send(JSON.stringify({
    type: 'mark_read',
    messageId: messageId
  }));
}

// Handle disconnection
ws.onclose = (event) => {
  console.log('WebSocket connection closed:', event.code, event.reason);
  // Implement reconnection logic here
};

// Handle errors
ws.onerror = (error) => {
  console.error('WebSocket error:', error);
};
```

### Error Handling

**Common Error Responses:**

1. **Unauthorized (401)**
```json
{
  "error": "Unauthorized - authentication required"
}
```

2. **Blocked User (400)**
```json
{
  "error": "Cannot send message to a blocked user"
}
```

3. **Invalid Message (400)**
```json
{
  "error": "Message content must not be empty"
}
```

4. **Forbidden (403)**
```json
{
  "error": "Only the receiver can mark a message as read"
}
```
