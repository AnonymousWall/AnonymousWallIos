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
    @State private var currentPost: Post
    @State private var comments: [Comment] = []
    @State private var isLoadingComments = false
    @State private var isLoadingMoreComments = false
    @State private var currentPage = 1
    @State private var hasMorePages = true
    @State private var commentText = ""
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @State private var showDeleteConfirmation = false
    @State private var commentToDelete: Comment?
    @State private var selectedSortOrder: SortOrder = .newest
    
    init(post: Post) {
        self.post = post
        self._currentPost = State(initialValue: post)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Post content
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Original post
                    VStack(alignment: .leading, spacing: 14) {
                        // Post title
                        Text(currentPost.title)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        Text(currentPost.content)
                            .font(.system(size: 16))
                            .foregroundColor(.primary)
                            .lineSpacing(2)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        HStack(spacing: 16) {
                            HStack(spacing: 4) {
                                Image(systemName: "clock")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                Text(DateFormatting.formatRelativeTime(currentPost.createdAt))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            HStack(spacing: 16) {
                                // Like button
                                Button(action: {
                                    HapticFeedback.medium()
                                    toggleLike()
                                }) {
                                    HStack(spacing: 5) {
                                        Image(systemName: currentPost.liked ? "heart.fill" : "heart")
                                            .font(.system(size: 16))
                                            .foregroundColor(currentPost.liked ? .pink : .secondary)
                                        Text("\(currentPost.likes)")
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                            .foregroundColor(currentPost.liked ? .pink : .secondary)
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(currentPost.liked ? Color.pink.opacity(0.15) : Color(.systemGray6))
                                    .cornerRadius(8)
                                }
                                .buttonStyle(.bounce)
                                
                                HStack(spacing: 5) {
                                    Image(systemName: "bubble.left.fill")
                                        .font(.system(size: 16))
                                        .foregroundColor(.vibrantTeal)
                                    Text("\(currentPost.comments)")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.vibrantTeal)
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
                                    resetPagination()
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
                                .onAppear {
                                    // Load more when the last comment appears
                                    if comment.id == comments.last?.id {
                                        loadMoreCommentsIfNeeded()
                                    }
                                }
                            }
                            
                            // Loading indicator at bottom
                            if isLoadingMoreComments {
                                HStack {
                                    Spacer()
                                    ProgressView()
                                        .padding()
                                    Spacer()
                                }
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
                
                Button(action: {
                    HapticFeedback.light()
                    submitComment()
                }) {
                    if isSubmitting {
                        ProgressView()
                            .frame(width: 32, height: 32)
                    } else {
                        ZStack {
                            Circle()
                                .fill(commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? AnyShapeStyle(Color.gray.opacity(0.3)) : AnyShapeStyle(Color.purplePinkGradient))
                                .frame(width: 36, height: 36)
                            
                            Image(systemName: "arrow.up")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .shadow(color: commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.clear : Color.primaryPurple.opacity(0.3), radius: 4, x: 0, y: 2)
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
    
    /// Reset pagination to initial state
    private func resetPagination() {
        currentPage = 1
        hasMorePages = true
    }
    
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
                page: currentPage,
                limit: 20,
                sort: selectedSortOrder
            )
            // Replace comments (used for initial load and refresh)
            comments = response.data
            hasMorePages = currentPage < response.pagination.totalPages
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
        resetPagination()
        let task = Task {
            await loadComments()
        }
        
        // Wait for the task to complete
        await task.value
    }
    
    private func loadMoreCommentsIfNeeded() {
        guard !isLoadingMoreComments && hasMorePages else { return }
        
        Task { @MainActor in
            // Check again inside the task to prevent race condition
            guard !isLoadingMoreComments && hasMorePages else { return }
            
            isLoadingMoreComments = true
            await loadMoreComments()
        }
    }
    
    @MainActor
    private func loadMoreComments() async {
        guard let token = authState.authToken,
              let userId = authState.currentUser?.id else {
            isLoadingMoreComments = false
            return
        }
        
        defer {
            isLoadingMoreComments = false
        }
        
        // Calculate next page
        let nextPage = currentPage + 1
        
        do {
            let response = try await PostService.shared.getComments(
                postId: post.id,
                token: token,
                userId: userId,
                page: nextPage,
                limit: 20,
                sort: selectedSortOrder
            )
            
            // Update page number only after successful response
            currentPage = nextPage
            
            comments.append(contentsOf: response.data)
            hasMorePages = currentPage < response.pagination.totalPages
        } catch is CancellationError {
            return
        } catch NetworkError.cancelled {
            return
        } catch {
            errorMessage = error.localizedDescription
        }
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
                    HapticFeedback.success()
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
    
    private func toggleLike() {
        guard let token = authState.authToken,
              let userId = authState.currentUser?.id else {
            errorMessage = "Authentication required to like post."
            return
        }
        
        Task {
            do {
                let response = try await PostService.shared.toggleLike(postId: currentPost.id, token: token, userId: userId)
                
                // Update the post with response data (no need for second API call)
                await MainActor.run {
                    currentPost = currentPost.withUpdatedLike(liked: response.liked, likes: response.likeCount)
                }
            } catch is CancellationError {
                // Silently handle cancellation
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
                            errorMessage = "You don't have permission to like this post."
                        case .noConnection:
                            errorMessage = "No internet connection. Please check your network."
                        default:
                            errorMessage = "Failed to like post. Please try again."
                        }
                    } else {
                        errorMessage = "Failed to like post. Please try again."
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
        HStack(spacing: 0) {
            // Add leading spacer for own comments (push to right)
            if isOwnComment {
                Spacer()
                    .frame(minWidth: 40)
            }
            
            HStack(alignment: .top, spacing: 12) {
                // Comment content
                VStack(alignment: .leading, spacing: 4) {
                    // Author name
                    Text(isOwnComment ? "Me" : comment.author.profileName)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(isOwnComment ? .white : .blue)
                    
                    Text(comment.text)
                        .font(.body)
                        .foregroundColor(isOwnComment ? .white : .primary)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Text(DateFormatting.formatRelativeTime(comment.createdAt))
                        .font(.caption2)
                        .foregroundColor(isOwnComment ? Color.white.opacity(0.8) : .gray)
                }
                
                Spacer()
                
                // Delete button (only for own comments)
                if isOwnComment {
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .font(.caption)
                            .foregroundColor(.white)
                    }
                }
            }
            .padding()
            .background(isOwnComment ? Color.blue : Color(.secondarySystemBackground))
            .cornerRadius(8)
            
            // Add trailing spacer for other users' comments (push to left)
            if !isOwnComment {
                Spacer()
                    .frame(minWidth: 40)
            }
        }
        .padding(.horizontal)
    }
}

#Preview {
    NavigationStack {
        PostDetailView(
            post: Post(
                id: "1",
                title: "Sample Post Title",
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
