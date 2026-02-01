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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Post content
            Text(post.content)
                .font(.body)
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)
            
            // Footer with time and actions
            HStack {
                // Timestamp
                Text(formatDate(post.createdAt))
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
    
    private func formatDate(_ dateString: String) -> String {
        // Try to parse ISO 8601 date
        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: dateString) {
            let now = Date()
            let timeInterval = now.timeIntervalSince(date)
            
            // Less than a minute
            if timeInterval < 60 {
                return "Just now"
            }
            // Less than an hour
            else if timeInterval < 3600 {
                let minutes = Int(timeInterval / 60)
                return "\(minutes)m ago"
            }
            // Less than a day
            else if timeInterval < 86400 {
                let hours = Int(timeInterval / 3600)
                return "\(hours)h ago"
            }
            // Less than a week
            else if timeInterval < 604800 {
                let days = Int(timeInterval / 86400)
                return "\(days)d ago"
            }
            // More than a week
            else {
                let dateFormatter = DateFormatter()
                dateFormatter.dateStyle = .medium
                dateFormatter.timeStyle = .none
                return dateFormatter.string(from: date)
            }
        }
        
        // Fallback if date parsing fails
        return dateString
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
