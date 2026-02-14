# Accessibility Guide

## Overview
This document outlines the accessibility improvements implemented in the Anonymous Wall iOS app to ensure WCAG compliance and an excellent user experience for all users, including those using VoiceOver and other assistive technologies.

## Implementation Summary

### 1. Accessibility Labels and Hints
All interactive elements now include proper accessibility labels and hints to provide context for VoiceOver users.

#### PostRowView
- **Wall Badge**: "Posted on [Campus/National] wall"
- **Author Name**: "Posted by you" or "Posted by [profile name]"
- **Post Title**: "Post title: [title text]"
- **Post Content**: "Post content: [content text]" with hint "Tap to view full post"
- **Timestamp**: "Posted [relative time]"
- **Like Button**: 
  - Label: "Like" or "Unlike"
  - Value: "[count] likes"
  - Hint: "Double tap to like this post" or "Double tap to remove your like"
- **Comment Indicator**: "[count] comments"
- **Delete Button**: "Delete post" with hint "Double tap to delete this post"

#### PostDetailView
- **Post Title**: "Post title: [title text]"
- **Post Content**: "Post content: [content text]"
- **Timestamp**: "Posted [relative time]"
- **Like Button**: Same as PostRowView
- **Comment Count**: "[count] comments"
- **Comment Text Field**: "Comment text field" with hint "Enter your comment here"
- **Submit Button**: "Submit comment" with hint "Double tap to post your comment"
- **Sort Picker**: "Sort comments"
- **Post Options Menu**: "Post options"
- **Empty State**: "No comments yet. Be the first to comment!"

#### CommentRowView
- **Author**: "Your comment" or "Comment by [profile name]"
- **Comment Text**: "Comment: [text]"
- **Timestamp**: "Posted [relative time]"
- **Delete Button**: "Delete comment" with hint "Double tap to delete this comment"
- **Report Button**: "Report comment" with hint "Double tap to report this comment"

#### CreatePostView
- **Wall Picker**: "Select wall type" with current value
- **Title Section**: "Post title" with hint "Enter the title for your post"
- **Character Count**: "Character count: [current] of [maximum]"
- **Content Editor**: "Post content" with hint "Enter the content for your post"
- **Submit Button**: "Submit post" with appropriate hint based on enabled state
- **Cancel Button**: "Cancel" with hint "Double tap to cancel creating a post"

#### HomeView & CampusView
- **Sort Picker**: "Sort posts" with current sort order value
- **Empty State**: "No [national/campus] posts yet. Be the first to post!"
- **Post Navigation**: "View post: [title]" with hint "Double tap to view full post and comments"

#### ProfileView
- **Avatar**: "Profile avatar"
- **Email**: "Email: [email address]"
- **Profile Name**: "Profile name: [name]"
- **Content Picker**: "Content type" with value "Posts" or "Comments"
- **Sort Menu**: "Sort by" with current sort order
- **Empty States**: 
  - Posts: "No posts yet. Create your first post!"
  - Comments: "No comments yet. Start commenting on posts!"
- **Profile Menu**: "Profile menu" with hint "Double tap to access profile settings"

#### CreatePostTabView
- **Create Button**: "Create new post" with hint "Double tap to start creating a new post"

### 2. Dynamic Type Support
All hardcoded font sizes have been replaced with semantic font styles that support Dynamic Type:

#### Before (Hardcoded):
```swift
.font(.system(size: 18, weight: .bold))  // Post title
.font(.system(size: 15))                  // Post content
.font(.system(size: 16))                  // Icons
```

#### After (Dynamic Type):
```swift
.font(.title3.bold())      // Post title
.font(.subheadline)        // Post content
.font(.callout)            // Icons
.font(.body)               // Standard text
.font(.caption)            // Small text
```

### Font Mapping
- **Large Text**: `.largeTitle`, `.title`, `.title2`, `.title3`
- **Body Text**: `.body`, `.subheadline`
- **Small Text**: `.caption`, `.caption2`
- **Icons**: `.callout` for interactive elements

### 3. Accessibility Traits and Element Grouping

#### Header Traits
Section headers use `.accessibilityAddTraits(.isHeader)`:
- "Title" in CreatePostView
- "Content" in CreatePostView
- "Comments" in PostDetailView

#### Combined Elements
Related elements are grouped using `.accessibilityElement(children: .combine)`:
- Timestamp with clock icon
- Comment count with bubble icon
- Empty state messages

#### Hidden Elements
Decorative elements are hidden from VoiceOver using `.accessibilityHidden(true)`:
- Large decorative icons in empty states
- Background gradient circles

### 4. VoiceOver Navigation Best Practices

#### Logical Reading Order
Views are structured to ensure VoiceOver reads content in a logical order:
1. Header/title information
2. Main content
3. Action buttons
4. Secondary information

#### Meaningful Context
Labels provide complete context without being verbose:
- ✅ "Like post. 5 likes. Double tap to like this post"
- ❌ "Button. Heart icon. 5"

#### Dynamic Values
Accessibility values update to reflect current state:
- Like count updates when liking/unliking
- Sort order reflects current selection
- Character counts update in real-time

## Testing Accessibility

### Using VoiceOver on Simulator
1. Enable VoiceOver: Settings > Accessibility > VoiceOver
2. Navigate with two-finger swipe
3. Activate elements with double-tap
4. Verify all interactive elements are announced clearly

### Using Accessibility Inspector (Xcode)
1. Open Xcode > Developer Tools > Accessibility Inspector
2. Select the running app
3. Use the inspection mode to verify:
   - All elements have labels
   - Reading order is logical
   - Dynamic Type scales correctly

### Testing Dynamic Type
1. Settings > Accessibility > Display & Text Size > Larger Text
2. Adjust text size slider
3. Verify:
   - Text scales appropriately
   - No text truncation at larger sizes
   - Layout doesn't break

### Manual Test Checklist
- [ ] All buttons are accessible with descriptive labels
- [ ] Post rows announce title, content, and interaction options
- [ ] Comments section provides clear navigation
- [ ] Form fields have labels and hints
- [ ] Empty states provide helpful context
- [ ] Sort pickers announce current selection
- [ ] Character counters announce counts
- [ ] Navigation is logical and predictable

## WCAG 2.1 Compliance

### Level A (Must Have)
- ✅ **1.1.1 Non-text Content**: All icons have text alternatives
- ✅ **2.1.1 Keyboard**: All functionality accessible via VoiceOver gestures
- ✅ **2.4.2 Page Titled**: Navigation titles clearly identify purpose
- ✅ **4.1.2 Name, Role, Value**: All UI components have accessible names

### Level AA (Should Have)
- ✅ **1.4.3 Contrast**: Text meets minimum contrast ratios
- ✅ **1.4.4 Resize Text**: Text scales up to 200% without loss of functionality
- ✅ **2.4.6 Headings and Labels**: Descriptive headings and labels
- ✅ **3.3.2 Labels or Instructions**: Input fields have clear labels

## Future Improvements

### Recommended Enhancements
1. **Custom Rotor Actions**: Add VoiceOver rotor actions for quick navigation
2. **Accessibility Announcements**: Use `UIAccessibility.post()` for dynamic content updates
3. **Voice Control**: Test and optimize for Voice Control users
4. **Switch Control**: Ensure compatibility with Switch Control
5. **Reduced Motion**: Respect user's reduced motion preferences
6. **High Contrast**: Support high contrast mode

### Testing with Real Users
- Conduct user testing with VoiceOver users
- Gather feedback from users with different accessibility needs
- Iterate based on real-world usage patterns

## References
- [Apple Accessibility Programming Guide](https://developer.apple.com/accessibility/)
- [WCAG 2.1 Guidelines](https://www.w3.org/WAI/WCAG21/quickref/)
- [iOS Human Interface Guidelines - Accessibility](https://developer.apple.com/design/human-interface-guidelines/accessibility)

## Support
For questions or issues related to accessibility, please open an issue on GitHub with the "accessibility" label.
