## API Documentation

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
- `sort` (default: "NEWEST") - Sort order: NEWEST, OLDEST, MOST_LIKED, LEAST_LIKED

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
- `sort` (default: "NEWEST") - Sort order: NEWEST, OLDEST, MOST_LIKED, LEAST_LIKED

**Notes:**
- Returns all posts created by the authenticated user
- Hidden (soft-deleted) posts are automatically excluded
- Uses optimized queries with composite database indexes for efficient retrieval
- Performance: O(log K) where K is the user's total post count
- Supports sorting by creation time or like count

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

---

## Authentication & Authorization

### JWT Token
- Tokens are generated upon successful login/registration
- Include token in `Authorization: Bearer {token}` header
- Token contains user ID as principal name
- Tokens expire after configured duration

### Visibility Rules

#### Campus Posts
- Only visible to users from **the same school domain**
- Users from other schools receive **403 Forbidden**
- Campus wall requires user to have a school domain

#### National Posts
- Visible to **all authenticated users**
- No school domain restriction

#### Comments & Likes
- Same visibility rules as posts apply
- Users from different schools cannot like/comment on campus posts

### User Authentication Flow
1. **Registration**: Email verification → Account creation → JWT issued
2. **Login (Email)**: Email code verification → JWT issued
3. **Login (Password)**: Email + password → JWT issued
4. **All Requests**: Include JWT in Authorization header