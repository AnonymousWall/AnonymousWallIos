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
    
    @State private var showDeleteConfirmation = false
    
    private var isCampusPost: Bool {
        post.wall.uppercased() == WallType.campus.rawValue.uppercased()
    }
    
    private var wallDisplayName: String {
        isCampusPost ? WallType.campus.displayName : WallType.national.displayName
    }
    
    private var wallColor: Color {
        isCampusPost ? .blue : .green
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Wall type badge
            HStack {
                Text(wallDisplayName)
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(wallColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(wallColor.opacity(0.15))
                    .cornerRadius(4)
                Spacer()
            }
            
            // Post content
            Text(post.content)
                .font(.body)
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)
            
            // Footer with time and actions
            HStack {
                // Timestamp
                Text(DateFormatting.formatRelativeTime(post.createdAt))
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Spacer()
                
                // Like button
                Button(action: onLike) {
                    HStack(spacing: 4) {
                        Image(systemName: post.liked ? "heart.fill" : "heart")
                            .foregroundColor(post.liked ? .red : .gray)
                        Text("\(post.likes)")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                
                // Comment count indicator
                HStack(spacing: 4) {
                    Image(systemName: "bubble.left")
                        .foregroundColor(.gray)
                    Text("\(post.comments)")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                // Delete button (only for own posts)
                if isOwnPost {
                    Button(action: { showDeleteConfirmation = true }) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
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
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

#Preview {
    PostRowView(
        post: Post(
            id: "1",
            content: "This is a sample anonymous post on the wall!",
            wall: "CAMPUS",
            likes: 5,
            comments: 2,
            liked: false,
            author: Post.Author(id: "user123", isAnonymous: true),
            createdAt: ISO8601DateFormatter().string(from: Date()),
            updatedAt: ISO8601DateFormatter().string(from: Date())
        ),
        isOwnPost: false,
        onLike: {},
        onDelete: {}
    )
    .padding()
}
