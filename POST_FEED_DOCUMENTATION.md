# Post Feed Feature Documentation

## Overview

The Anonymous Wall app now includes a complete post feed system where authenticated users can:
- Create anonymous posts
- View posts from all users
- Like/unlike posts
- Delete their own posts
- Refresh to see new posts

## Architecture

### Models

**Post.swift**
```swift
struct Post: Codable, Identifiable {
    let id: String
    let content: String
    let authorId: String
    let createdAt: String
    let likesCount: Int
    let isLikedByCurrentUser: Bool?
}
```

**Supporting Models:**
- `PostListResponse` - For paginated post lists
- `CreatePostRequest` - For creating new posts
- `CreatePostResponse` - Response after creating a post

### Services

**PostService.swift**

All endpoints use:
- Base URL: `http://localhost:8080`
- Authentication: `Authorization: Bearer {token}`
- User ID: `X-User-ID: {userId}`

**Methods:**
1. `fetchPosts(token:userId:page:limit:)` - Get list of posts
2. `createPost(content:token:userId:)` - Create a new post
3. `deletePost(postId:token:userId:)` - Delete a post
4. `likePost(postId:token:userId:)` - Like a post
5. `unlikePost(postId:token:userId:)` - Unlike a post

### Views

#### WallView (Main Feed)
- Displays list of posts in a scrollable feed
- Shows loading state while fetching posts
- Shows empty state when no posts exist
- Pull-to-refresh to reload posts
- Create post button (top left, pencil icon)
- Settings menu (top right, hamburger icon)

**States:**
- Loading: Shows spinner with "Loading posts..."
- Empty: Shows bubble icon with "No posts yet" message
- Populated: Shows list of posts with PostRowView components

#### CreatePostView
- Modal sheet for creating new posts
- Text editor with character limit (500 chars)
- Real-time character counter
- Cancel button (top left)
- Post button (bottom, disabled when invalid)
- Error message display

**Validation:**
- Content cannot be empty (after trimming whitespace)
- Content cannot exceed 500 characters
- Post button disabled during submission

#### PostRowView
- Displays individual post in the feed
- Shows post content
- Shows relative timestamp (e.g., "5m ago", "2h ago")
- Like button with heart icon and count
- Delete button (trash icon) for own posts only
- Confirmation dialog before deletion

**Visual Design:**
- White background with rounded corners
- Subtle shadow for depth
- Red heart when liked, gray when not
- Red trash icon for delete

## User Flows

### Creating a Post

1. User taps pencil icon (top left of WallView)
2. CreatePostView modal appears
3. User types post content (max 500 chars)
4. Character counter updates in real-time
5. User taps "Post" button
6. Post is created via API
7. Modal dismisses and feed refreshes
8. New post appears at top of feed

### Viewing Posts

1. User opens WallView after authentication
2. App automatically fetches posts from API
3. Posts display in scrollable list
4. Each post shows:
   - Content
   - Timestamp (relative)
   - Like count
   - Like button
   - Delete button (if user's own post)

### Liking a Post

1. User taps heart icon on a post
2. If not liked: API call to like the post, heart turns red
3. If already liked: API call to unlike, heart turns gray
4. Like count updates
5. Feed refreshes to show current state

### Deleting a Post

1. User taps trash icon on their own post
2. Confirmation dialog appears
3. User confirms deletion
4. API call to delete the post
5. Feed refreshes
6. Post is removed from the list

### Refreshing Feed

1. User pulls down on the post list
2. Refresh indicator appears
3. API call to fetch latest posts
4. Feed updates with new posts
5. Refresh indicator disappears

## API Endpoints

### Base URL
```
http://localhost:8080
```

### Headers (for authenticated endpoints)
```
Content-Type: application/json
Authorization: Bearer {accessToken}
X-User-ID: {userId}
```

### 1. List Posts

**Request:**
```http
GET /api/v1/posts?page=1&limit=20
```

**Response:**
```json
{
  "posts": [
    {
      "id": "post-uuid",
      "content": "This is an anonymous post!",
      "authorId": "user-uuid",
      "createdAt": "2026-02-01T07:00:00Z",
      "likesCount": 5,
      "isLikedByCurrentUser": false
    }
  ],
  "total": 42
}
```

Alternative response (simple array):
```json
[
  {
    "id": "post-uuid",
    "content": "This is an anonymous post!",
    "authorId": "user-uuid",
    "createdAt": "2026-02-01T07:00:00Z",
    "likesCount": 5,
    "isLikedByCurrentUser": false
  }
]
```

### 2. Create Post

**Request:**
```http
POST /api/v1/posts
Content-Type: application/json
Authorization: Bearer {token}
X-User-ID: {userId}

{
  "content": "This is my new anonymous post!"
}
```

**Response:**
```json
{
  "post": {
    "id": "new-post-uuid",
    "content": "This is my new anonymous post!",
    "authorId": "user-uuid",
    "createdAt": "2026-02-01T07:05:00Z",
    "likesCount": 0,
    "isLikedByCurrentUser": false
  }
}
```

Alternative response (simple post object):
```json
{
  "id": "new-post-uuid",
  "content": "This is my new anonymous post!",
  "authorId": "user-uuid",
  "createdAt": "2026-02-01T07:05:00Z",
  "likesCount": 0,
  "isLikedByCurrentUser": false
}
```

### 3. Like Post

**Request:**
```http
POST /api/v1/posts/{postId}/like
Authorization: Bearer {token}
X-User-ID: {userId}
```

**Response:**
```
200 OK
```

### 4. Unlike Post

**Request:**
```http
DELETE /api/v1/posts/{postId}/like
Authorization: Bearer {token}
X-User-ID: {userId}
```

**Response:**
```
200 OK
```

### 5. Delete Post

**Request:**
```http
DELETE /api/v1/posts/{postId}
Authorization: Bearer {token}
X-User-ID: {userId}
```

**Response:**
```
200 OK
```

## UI Components

### WallView Layout

```
┌─────────────────────────────────────┐
│ ✏️         Wall              ☰      │
├─────────────────────────────────────┤
│ ⚠️ Password Setup Banner (optional) │
├─────────────────────────────────────┤
│                                     │
│  ┌─────────────────────────────┐   │
│  │ Post Content Here...        │   │
│  │                             │   │
│  │ 5m ago        ❤️ 3    🗑️    │   │
│  └─────────────────────────────┘   │
│                                     │
│  ┌─────────────────────────────┐   │
│  │ Another post content...     │   │
│  │                             │   │
│  │ 1h ago        🤍 1          │   │
│  └─────────────────────────────┘   │
│                                     │
└─────────────────────────────────────┘
```

### CreatePostView Layout

```
┌─────────────────────────────────────┐
│ Cancel      New Post                │
├─────────────────────────────────────┤
│                         125/500     │
│                                     │
│  ┌─────────────────────────────┐   │
│  │                             │   │
│  │  Type your post here...     │   │
│  │                             │   │
│  │                             │   │
│  │                             │   │
│  └─────────────────────────────┘   │
│                                     │
│                                     │
│  ┌─────────────────────────────┐   │
│  │          Post               │   │  
│  └─────────────────────────────┘   │
└─────────────────────────────────────┘
```

## Error Handling

**Network Errors:**
- Displayed as red text at bottom of WallView
- User can retry by pulling to refresh

**Authentication Errors (401):**
- Throws `AuthError.unauthorized`
- User should be logged out automatically

**Validation Errors:**
- Empty post: "Post cannot be empty"
- Too long: "Post exceeds maximum length"
- Not authenticated: "Not authenticated"

## Testing Recommendations

### Manual Testing Checklist
- [ ] Create a post with valid content
- [ ] Try to create empty post (should be disabled)
- [ ] Try to create post over 500 chars (should be disabled)
- [ ] View list of posts
- [ ] Like a post (heart should turn red, count increases)
- [ ] Unlike a post (heart should turn gray, count decreases)
- [ ] Delete own post (should show confirmation)
- [ ] Try to delete someone else's post (button shouldn't appear)
- [ ] Pull to refresh the feed
- [ ] View feed when no posts exist
- [ ] Test with network offline (should show error)

### Backend Requirements
- Implement all 5 API endpoints
- Return appropriate HTTP status codes
- Include `isLikedByCurrentUser` in post responses
- Filter posts to only show posts user has permission to see
- Only allow users to delete their own posts

## Future Enhancements

Potential features to add:
- [ ] Pagination (load more posts as user scrolls)
- [ ] Comments on posts
- [ ] Post reactions (beyond just likes)
- [ ] Report inappropriate content
- [ ] Search/filter posts
- [ ] User profiles (while maintaining anonymity)
- [ ] Post categories/tags
- [ ] Sort options (latest, most liked, trending)
- [ ] Draft posts (save before posting)
- [ ] Edit posts (within time limit)
