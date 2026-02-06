//
//  PostDetailView.swift
//  AnonymousWallIos
//
//  Detail view for a post showing comments
//

import SwiftUI

struct PostDetailView: View {
    @EnvironmentObject var authState: AuthState
    @Environment(\.dismiss) var dismiss
    
    let post: Post
    @State private var comments: [Comment] = []
    @State private var isLoadingComments = false
    @State private var commentText = ""
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @State private var showDeleteConfirmation = false
    @State private var commentToDelete: Comment?
    @State private var selectedSortOrder: SortOrder = .newest
    
    var body: some View {
        VStack(spacing: 0) {
            // Post content
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Original post
                    VStack(alignment: .leading, spacing: 12) {
                        Text(post.content)
                            .font(.body)
                            .foregroundColor(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        HStack {
                            Text(DateFormatting.formatRelativeTime(post.createdAt))
                                .font(.caption)
                                .foregroundColor(.gray)
                            
                            Spacer()
                            
                            HStack(spacing: 16) {
                                HStack(spacing: 4) {
                                    Image(systemName: "heart.fill")
                                        .foregroundColor(.gray)
                                    Text("\(post.likes)")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                
                                HStack(spacing: 4) {
                                    Image(systemName: "bubble.left")
                                        .foregroundColor(.gray)
                                    Text("\(post.comments)")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(10)
                    .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                    
                    Divider()
                        .padding(.vertical, 8)
                    
                    // Comments section header with sorting
                    HStack {
                        Text("Comments")
                            .font(.headline)
                        
                        Spacer()
                        
                        // Sort order picker for comments
                        if !comments.isEmpty {
                            Picker("Sort", selection: $selectedSortOrder) {
                                Text("Newest").tag(SortOrder.newest)
                                Text("Oldest").tag(SortOrder.oldest)
                            }
                            .pickerStyle(.menu)
                            .onChange(of: selectedSortOrder) { _, _ in
                                Task {
                                    await loadComments()
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                    
                    if isLoadingComments && comments.isEmpty {
                        HStack {
                            Spacer()
                            ProgressView("Loading comments...")
                            Spacer()
                        }
                        .padding()
                    } else if comments.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "bubble.left.and.bubble.right")
                                .font(.system(size: 40))
                                .foregroundColor(.gray)
                            Text("No comments yet")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            Text("Be the first to comment!")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 32)
                    } else {
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(comments) { comment in
                                CommentRowView(
                                    comment: comment,
                                    isOwnComment: comment.author.id == authState.currentUser?.id,
                                    onDelete: {
                                        commentToDelete = comment
                                        showDeleteConfirmation = true
                                    }
                                )
                            }
                        }
                    }
                }
                .padding()
            }
            .refreshable {
                await refreshComments()
            }
            
            // Error message
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
                    .padding(.horizontal)
                    .padding(.vertical, 8)
            }
            
            Divider()
            
            // Comment input
            HStack(spacing: 12) {
                TextField("Add a comment...", text: $commentText, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(1...4)
                    .disabled(isSubmitting)
                    .accessibilityLabel("Comment text field")
                
                Button(action: submitComment) {
                    if isSubmitting {
                        ProgressView()
                            .frame(width: 24, height: 24)
                    } else {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title2)
                            .foregroundColor(commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .gray : .blue)
                    }
                }
                .disabled(commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSubmitting)
            }
            .padding()
            .background(Color(.systemBackground))
        }
        .navigationTitle("Post Details")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            Task {
                await loadComments()
            }
        }
        .confirmationDialog(
            "Delete Comment",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if let comment = commentToDelete {
                    deleteComment(comment)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete this comment?")
        }
    }
    
    // MARK: - Functions
    
    @MainActor
    private func loadComments() async {
        guard let token = authState.authToken,
              let userId = authState.currentUser?.id else {
            errorMessage = "Authentication required to load comments."
            return
        }
        
        isLoadingComments = true
        errorMessage = nil
        
        defer {
            isLoadingComments = false
        }
        
        do {
            let response = try await PostService.shared.getComments(
                postId: post.id,
                token: token,
                userId: userId,
                sort: selectedSortOrder
            )
            comments = response.data
        } catch is CancellationError {
            // Silently handle cancellation - this is expected behavior
            return
        } catch NetworkError.cancelled {
            // Silently handle network cancellation - this is expected behavior during refresh
            return
        } catch {
            errorMessage = "Failed to load comments: \(error.localizedDescription)"
        }
    }
    
    @MainActor
    private func refreshComments() async {
        // Create a new task that won't be cancelled by the refreshable gesture
        // This ensures refresh works correctly when user releases before completion
        let task = Task {
            await loadComments()
        }
        
        // Wait for the task to complete
        await task.value
    }
    
    private func submitComment() {
        let trimmedText = commentText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty,
              let token = authState.authToken,
              let userId = authState.currentUser?.id else {
            return
        }
        
        isSubmitting = true
        errorMessage = nil
        
        Task {
            do {
                _ = try await PostService.shared.addComment(
                    postId: post.id,
                    text: trimmedText,
                    token: token,
                    userId: userId
                )
                
                await MainActor.run {
                    commentText = ""
                    isSubmitting = false
                }
                
                // Reload comments
                await loadComments()
            } catch is CancellationError {
                // Silently handle cancellation - user likely navigated away
                await MainActor.run {
                    isSubmitting = false
                }
            } catch NetworkError.cancelled {
                // Silently handle network cancellation
                await MainActor.run {
                    isSubmitting = false
                }
            } catch {
                await MainActor.run {
                    isSubmitting = false
                    errorMessage = "Failed to post comment: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func deleteComment(_ comment: Comment) {
        guard let token = authState.authToken,
              let userId = authState.currentUser?.id else {
            errorMessage = "Authentication required to delete comment."
            return
        }
        
        Task {
            do {
                _ = try await PostService.shared.hideComment(
                    postId: post.id,
                    commentId: comment.id,
                    token: token,
                    userId: userId
                )
                // Reload comments
                await loadComments()
            } catch is CancellationError {
                // Silently handle cancellation - user likely navigated away
                return
            } catch NetworkError.cancelled {
                // Silently handle network cancellation
                return
            } catch {
                await MainActor.run {
                    if let networkError = error as? NetworkError {
                        switch networkError {
                        case .unauthorized:
                            errorMessage = "Session expired. Please log in again."
                        case .forbidden:
                            errorMessage = "You don't have permission to delete this comment."
                        case .notFound:
                            errorMessage = "Comment not found."
                        case .noConnection:
                            errorMessage = "No internet connection. Please check your network."
                        default:
                            errorMessage = "Failed to delete comment. Please try again."
                        }
                    } else {
                        errorMessage = "Failed to delete comment. Please try again."
                    }
                }
            }
        }
    }
}

// MARK: - Comment Row View

struct CommentRowView: View {
    let comment: Comment
    let isOwnComment: Bool
    var onDelete: () -> Void
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Comment content
            VStack(alignment: .leading, spacing: 4) {
                // Author name
                Text(comment.author.profileName)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
                
                Text(comment.text)
                    .font(.body)
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)
                
                Text(DateFormatting.formatRelativeTime(comment.createdAt))
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            // Delete button (only for own comments)
            if isOwnComment {
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(8)
        .padding(.horizontal)
    }
}

#Preview {
    NavigationStack {
        PostDetailView(
            post: Post(
                id: "1",
                content: "This is a sample post with some interesting content that people might want to comment on!",
                wall: "CAMPUS",
                likes: 5,
                comments: 2,
                liked: false,
                author: Post.Author(id: "user123", profileName: "Anonymous", isAnonymous: true),
                createdAt: ISO8601DateFormatter().string(from: Date()),
                updatedAt: ISO8601DateFormatter().string(from: Date())
            )
        )
        .environmentObject(AuthState())
    }
}
