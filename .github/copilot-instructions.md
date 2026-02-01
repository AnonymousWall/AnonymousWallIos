## Backend API Documentation

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
    "isVerified": true,
    "passwordSet": true,
    "createdAt": "2026-01-28T..."
}
```

#### 6. Change Password (Requires Authentication)
```http
POST /api/v1/auth/password/change
Header: X-User-Id: {userId}
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
    "isVerified": true,
    "passwordSet": true,
    "createdAt": "2026-01-28T..."
}
```

#### 7. Reset Password (Forgot password)
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

#### 8. Reset Password with Verification Code
```http
POST /api/v1/auth/password/reset
Content-Type: application/json

{
    "email": "student@nyu.edu",
    "code": "339124",
    "newPassword": "myNewPassword789"
}

{
    "accessToken": "eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiI4NDA1ZTA4Mi0wOGNjLTQ3MTEtYmZiMC01OTQzNDc2MzgxNWIiLCJuYmYiOjE3Njk4MTQzNTIsInJvbGVzIjpbXSwiaXNzIjoiYW5vbnltb3Vzd2FsbCIsInZlcmlmaWVkIjp0cnVlLCJleHAiOjE3Njk5MDA3NTIsInBhc3N3b3JkU2V0Ijp0cnVlLCJpYXQiOjE3Njk4MTQzNTIsImVtYWlsIjoic3R1ZGVudEBueXUuZWR1In0.9gca3eDLfWdYujECxhnRS7-zNMJMkdWn8WloiSpcpRs",
    "user": {
        "id": "8405e082-08cc-4711-bfb0-59434763815b",
        "email": "student@nyu.edu",
        "isVerified": true,
        "createdAt": "2026-01-30T15:01:22-08:00[America/Los_Angeles]"
    }
}
```

---

### Post Endpoints

#### 1. Create Post
```http
POST /api/v1/posts
Authorization: Bearer {jwt-token}
Content-Type: application/json

{
    "content": "This is my first post!",
    "wall": "campus"  // or "national"
}

Response: 201 Created
{
    "id": "1",
    "content": "This is my first post!",
    "wall": "CAMPUS",
    "likes": 0,
    "comments": 0,
    "liked": false,
    "author": {
        "id": "uuid",
        "isAnonymous": true
    },
    "createdAt": "2026-01-28T...",
    "updatedAt": "2026-01-28T..."
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

#### 3. Toggle Like on Post
```http
POST /api/v1/posts/{postId}/likes
Authorization: Bearer {jwt-token}

Response: 200 OK
{
    "liked": true  // or false if unlike
}
```

#### 4. Add Comment
```http
POST /api/v1/posts/{postId}/comments
Authorization: Bearer {jwt-token}
Content-Type: application/json

{
    "text": "Great post!"
}

Response: 201 Created
{
    "id": "1",
    "postId": "1",
    "text": "Great post!",
    "author": {
        "id": "uuid",
        "isAnonymous": true
    },
    "createdAt": "2026-01-28T..."
}
```

#### 5. Get Comments for Post
```http
GET /api/v1/posts/{postId}/comments?page=1&limit=20&sort=NEWEST
Authorization: Bearer {jwt-token}

Response: 200 OK
{
    "data": [
        {
            "id": "1",
            "postId": "1",
            "text": "Great post!",
            "author": {
                "id": "uuid",
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



### HTTP Status Codes
- `200 OK` - Success
- `201 Created` - Resource created
- `400 Bad Request` - Invalid input
- `401 Unauthorized` - Missing/invalid JWT token
- `403 Forbidden` - User doesn't have access (wrong school domain)
- `404 Not Found` - Resource not found
- `409 Conflict` - Resource already exists (email already registered)
- `500 Internal Server Error` - Server error
