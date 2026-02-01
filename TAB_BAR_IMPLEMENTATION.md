# Tab Bar Navigation Implementation

## Overview

This document describes the implementation of the tab bar navigation system that replaced the single-view wall interface.

## Architecture

### Tab Bar Structure

The app now uses a `TabBarView` as the main authenticated interface with 6 tabs:

1. **Home** (National Wall) - `HomeView.swift`
   - Shows posts from the national wall
   - Accessible to all authenticated users regardless of school
   - Icon: house.fill

2. **Campus** (Campus Wall) - `CampusView.swift`
   - Shows posts from the user's campus wall
   - Only shows posts from the same school domain
   - Icon: building.2.fill

3. **Internship** - `InternshipView.swift`
   - Placeholder view for future internship feature
   - Icon: briefcase.fill

4. **Market** - `MarketView.swift`
   - Placeholder view for future marketplace feature
   - Icon: cart.fill

5. **Create** - `CreatePostTabView.swift`
   - Wrapper view that opens the create post sheet
   - Users can choose to post to either campus or national wall
   - Icon: plus.circle.fill

6. **Profile** - `ProfileView.swift`
   - Shows user's own posts and comments
   - Segmented control to switch between posts and comments
   - Icon: person.fill

## Implementation Details

### TabBarView.swift

Main container view that manages the tab navigation using SwiftUI's `TabView`:

```swift
TabView(selection: $selectedTab) {
    HomeView().tabItem { Label("Home", systemImage: "house.fill") }.tag(0)
    CampusView().tabItem { Label("Campus", systemImage: "building.2.fill") }.tag(1)
    InternshipView().tabItem { Label("Internship", systemImage: "briefcase.fill") }.tag(2)
    MarketView().tabItem { Label("Market", systemImage: "cart.fill") }.tag(3)
    CreatePostTabView().tabItem { Label("Create", systemImage: "plus.circle.fill") }.tag(4)
    ProfileView().tabItem { Label("Profile", systemImage: "person.fill") }.tag(5)
}
```

### HomeView.swift

Displays national posts with the following features:
- Fetches posts from the national wall using `PostService.shared.fetchPosts(wall: .national)`
- Pull-to-refresh support
- Like/unlike functionality
- Navigation to post details
- Delete own posts
- Password setup reminder banner

### CampusView.swift

Similar to HomeView but for campus posts:
- Fetches posts from the campus wall using `PostService.shared.fetchPosts(wall: .campus)`
- Same features as HomeView
- Posts are restricted to users from the same school domain

### ProfileView.swift

Shows user's own content with advanced filtering:
- Segmented control to switch between "Posts" and "Comments"
- **Posts Tab**: 
  - Fetches both campus and national posts
  - Filters to show only posts where `author.id == currentUser.id`
  - Sorted by creation date (newest first)
- **Comments Tab**:
  - Fetches all posts and their comments
  - Filters to show only comments where `author.id == currentUser.id`
  - Sorted by creation date (newest first)
- Pull-to-refresh support on both tabs

### CreatePostTabView.swift

Wrapper view for the create post functionality:
- Automatically opens the create post sheet when tab is selected
- Reuses the existing `CreatePostView` component
- Users can select wall type (campus/national) before posting

### InternshipView.swift & MarketView.swift

Placeholder views for future features:
- Simple centered layout with icon, title, and "Coming Soon" message
- Ready to be replaced with actual implementation

## API Integration

The implementation uses existing API endpoints:

- `GET /api/v1/posts?wall={campus|national}` - Fetch posts by wall type
- `POST /api/v1/posts` - Create new post
- `POST /api/v1/posts/{postId}/likes` - Toggle like
- `GET /api/v1/posts/{postId}/comments` - Get comments
- `PATCH /api/v1/posts/{postId}/hide` - Hide/delete post

## State Management

All views use the shared `AuthState` environment object:
- `@EnvironmentObject var authState: AuthState`
- Access to current user info, auth token, and password setup status
- Logout functionality available from menu in each view

## Navigation

Each tab has its own `NavigationStack`:
- Allows independent navigation within each tab
- Post detail views open within their respective tab's navigation stack
- Back navigation returns to the tab's root view

## User Experience

### Password Setup Flow
All views display a persistent banner if the user hasn't set a password yet:
- Orange alert banner at the top
- "Set Now" button to open password setup sheet
- Auto-shows password setup sheet on first view appearance

### Error Handling
All views include consistent error handling:
- Network errors displayed in red text
- User-friendly error messages
- Graceful handling of session expiration

### Loading States
- Loading indicator shown while fetching data
- Empty state messages when no content is available
- Skeleton views maintain layout during loading

## Testing

To test the implementation:

1. **Home Tab**: Verify national posts are displayed
2. **Campus Tab**: Verify campus posts are displayed
3. **Internship Tab**: Verify placeholder is shown
4. **Market Tab**: Verify placeholder is shown
5. **Create Tab**: Verify create post sheet opens
6. **Profile Tab**: 
   - Verify user's posts are shown
   - Switch to comments tab and verify comments are shown
   - Test pull-to-refresh on both tabs

## Migration from WallView

The original `WallView.swift` has been kept for backward compatibility but is no longer used:
- `AnonymousWallIosApp.swift` now uses `TabBarView` instead of `WallView`
- `WallView` can be removed in a future update if not needed

## Future Enhancements

1. **Internship Tab**: Implement job/internship posting and browsing
2. **Market Tab**: Implement item listing and marketplace
3. **Profile Tab**: 
   - Add user statistics (post count, comment count, likes received)
   - Add filtering and sorting options
   - Add edit post/comment functionality
4. **Notifications**: Add badge indicators for new activity
5. **Deep Linking**: Support direct links to specific tabs
