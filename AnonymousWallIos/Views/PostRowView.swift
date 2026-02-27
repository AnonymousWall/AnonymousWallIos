//
//  PostRowView.swift
//  AnonymousWallIos
//
//  Row view for displaying a single post
//

import SwiftUI

struct PostRowView: View {
    let post: Post
    let isOwnPost: Bool
    var onLike: () -> Void
    var onDelete: () -> Void
    var onTapAuthor: (() -> Void)?
    
    @EnvironmentObject var authState: AuthState
    @EnvironmentObject var blockViewModel: BlockViewModel
    @State private var showDeleteConfirmation = false
    @State private var selectedImageViewer: ImageViewerItem?
    @State private var showAuthorActionSheet = false
    @State private var showBlockSuccessAlert = false
    
    private var isCampusPost: Bool {
        post.wall.uppercased() == WallType.campus.rawValue.uppercased()
    }
    
    private var wallDisplayName: String {
        isCampusPost ? WallType.campus.displayName : WallType.national.displayName
    }
    
    private var wallColor: Color {
        isCampusPost ? .primaryPurple : .vibrantTeal
    }
    
    private var wallGradient: LinearGradient {
        isCampusPost ? Color.purplePinkGradient : Color.tealPurpleGradient
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Wall type badge and author name
            HStack(spacing: 10) {
                Text(wallDisplayName)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(wallGradient)
                    .cornerRadius(12)
                    .shadow(color: wallColor.opacity(0.3), radius: 4, x: 0, y: 2)
                    .accessibilityLabel("Posted on \(wallDisplayName) wall")
                
                if isOwnPost {
                    Text("by Me")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .accessibilityLabel("Posted by you")
                } else {
                    Button(action: {
                            HapticFeedback.selection()
                            showAuthorActionSheet = true
                        }) {
                        Text("by \(post.author.profileName)")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.blue)
                            .underline()
                    }
                    .accessibilityLabel("Posted by \(post.author.profileName)")
                    .accessibilityHint("Double tap to message or block \(post.author.profileName)")
                    .confirmationDialog(
                        post.author.profileName,
                        isPresented: $showAuthorActionSheet,
                        titleVisibility: .visible
                    ) {
                        Button("Message \(post.author.profileName)") {
                            onTapAuthor?()
                        }
                        Button("Block \(post.author.profileName)", role: .destructive) {
                            HapticFeedback.warning()
                            blockViewModel.blockUser(targetUserId: post.author.id, authState: authState) {
                                showBlockSuccessAlert = true
                            }
                        }
                        Button("Cancel", role: .cancel) {}
                    }
                }
                
                Spacer()
            }
            
            // Post title
            Text(post.title)
                .font(.title3.bold())
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityLabel("Post title: \(post.title)")
            
            // Post content
            Text(post.content)
                .font(.subheadline)
                .foregroundColor(.primary)
                .lineSpacing(2)
                .lineLimit(UIConstants.postRowContentMaxLines)
                .truncationMode(.tail)
                .accessibilityLabel("Post content: \(post.content)")
                .accessibilityHint("Tap to view full post")
            
            // Post images
            if !post.imageUrls.isEmpty {
                PostImageGallery(imageUrls: post.imageUrls, selectedImageViewer: $selectedImageViewer, accessibilityContext: "Post images")
            }
            
            // Footer with time and actions
            HStack(spacing: 16) {
                // Timestamp
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(DateFormatting.formatRelativeTime(post.createdAt))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Posted \(DateFormatting.formatRelativeTime(post.createdAt))")
                
                Spacer()
                
                // Like button
                Button(action: {
                    HapticFeedback.medium()
                    onLike()
                }) {
                    HStack(spacing: 5) {
                        Image(systemName: post.liked ? "heart.fill" : "heart")
                            .font(.callout)
                            .foregroundColor(post.liked ? .pink : .secondary)
                        Text("\(post.likes)")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(post.liked ? .pink : .secondary)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(post.liked ? Color.pink.opacity(0.15) : Color(.systemGray6))
                    .cornerRadius(8)
                }
                .buttonStyle(.bounce)
                .accessibilityLabel(post.liked ? "Unlike" : "Like")
                .accessibilityValue("\(post.likes) likes")
                .accessibilityHint(post.liked ? "Double tap to remove your like" : "Double tap to like this post")
                
                // Comment count indicator
                HStack(spacing: 5) {
                    Image(systemName: "bubble.left.fill")
                        .font(.callout)
                        .foregroundColor(.vibrantTeal)
                    Text("\(post.comments)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.vibrantTeal)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.vibrantTeal.opacity(0.15))
                .cornerRadius(8)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(post.comments) comments")
                
                // Delete button (only for own posts)
                if isOwnPost {
                    Button(action: { 
                        HapticFeedback.warning()
                        showDeleteConfirmation = true 
                    }) {
                        Image(systemName: "trash.fill")
                            .font(.callout)
                            .foregroundColor(.white)
                            .padding(6)
                            .background(Color.red)
                            .cornerRadius(8)
                    }
                    .buttonStyle(.bounce)
                    .accessibilityLabel("Delete post")
                    .accessibilityHint("Double tap to delete this post")
                    .confirmationDialog(
                        "Delete Post",
                        isPresented: $showDeleteConfirmation,
                        titleVisibility: .visible
                    ) {
                        Button("Delete", role: .destructive) {
                            onDelete()
                        }
                        Button("Cancel", role: .cancel) {}
                    } message: {
                        Text("Are you sure you want to delete this post?")
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(.systemGray5), lineWidth: 0.5)
        )
        .fullScreenCover(item: $selectedImageViewer) { item in
            FullScreenImageViewer(imageURLs: post.imageUrls, initialIndex: item.index)
        }
        .alert("User Blocked", isPresented: $showBlockSuccessAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("\(post.author.profileName) has been blocked.")
        }
        .alert("Error", isPresented: .init(
            get: { blockViewModel.errorMessage != nil },
            set: { if !$0 { blockViewModel.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { blockViewModel.errorMessage = nil }
        } message: {
            if let error = blockViewModel.errorMessage {
                Text(error)
            }
        }
    }
}

#Preview {
    PostRowView(
        post: Post(
            id: "1",
            title: "Sample Post Title",
            content: "This is a sample anonymous post on the wall! Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur.",
            wall: "CAMPUS",
            likes: 5,
            comments: 2,
            liked: false,
            author: Post.Author(id: "user123", profileName: "Anonymous", isAnonymous: true),
            createdAt: ISO8601DateFormatter().string(from: Date()),
            updatedAt: ISO8601DateFormatter().string(from: Date())
        ),
        isOwnPost: false,
        onLike: {},
        onDelete: {},
        onTapAuthor: {}
    )
    .environmentObject(AuthState())
    .environmentObject(BlockViewModel())
    .padding()
}
