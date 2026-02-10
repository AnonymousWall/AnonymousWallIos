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
    
    @Binding var post: Post
    @StateObject private var viewModel = PostDetailViewModel()
    @State private var showDeleteConfirmation = false
    @State private var showReportPostDialog = false
    @State private var showReportCommentDialog = false
    @State private var reportReason = ""
    @State private var showReportSuccessAlert = false
    @State private var reportSuccessMessage = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // Post content
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Original post
                    VStack(alignment: .leading, spacing: 14) {
                        // Post title
                        Text(post.title)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        Text(post.content)
                            .font(.system(size: 16))
                            .foregroundColor(.primary)
                            .lineSpacing(2)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        HStack(spacing: 16) {
                            HStack(spacing: 4) {
                                Image(systemName: "clock")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                Text(DateFormatting.formatRelativeTime(post.createdAt))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            HStack(spacing: 16) {
                                // Like button
                                Button(action: {
                                    HapticFeedback.medium()
                                    Task {
                                        await viewModel.toggleLike(post: $post, authState: authState)
                                    }
                                }) {
                                    HStack(spacing: 5) {
                                        Image(systemName: post.liked ? "heart.fill" : "heart")
                                            .font(.system(size: 16))
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
                                
                                HStack(spacing: 5) {
                                    Image(systemName: "bubble.left.fill")
                                        .font(.system(size: 16))
                                        .foregroundColor(.vibrantTeal)
                                    Text("\(post.comments)")
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
                        if !viewModel.comments.isEmpty {
                            Picker("Sort", selection: $viewModel.selectedSortOrder) {
                                Text("Newest").tag(SortOrder.newest)
                                Text("Oldest").tag(SortOrder.oldest)
                            }
                            .pickerStyle(.menu)
                            .onChange(of: viewModel.selectedSortOrder) { _, _ in
                                Task {
                                    await viewModel.sortOrderChanged(postId: post.id, authState: authState)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                    
                    if viewModel.isLoadingComments && viewModel.comments.isEmpty {
                        HStack {
                            Spacer()
                            ProgressView("Loading comments...")
                            Spacer()
                        }
                        .padding()
                    } else if viewModel.comments.isEmpty {
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
                            ForEach(viewModel.comments) { comment in
                                CommentRowView(
                                    comment: comment,
                                    isOwnComment: comment.author.id == authState.currentUser?.id,
                                    onDelete: {
                                        viewModel.commentToDelete = comment
                                        showDeleteConfirmation = true
                                    },
                                    onReport: {
                                        viewModel.commentToReport = comment
                                        showReportCommentDialog = true
                                    }
                                )
                                .onAppear {
                                    // Load more when the last comment appears
                                    Task {
                                        await viewModel.loadMoreCommentsIfNeeded(for: comment, postId: post.id, authState: authState)
                                    }
                                }
                            }
                            
                            // Loading indicator at bottom
                            if viewModel.isLoadingMoreComments {
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
            
            // Error message
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
                    .padding(.horizontal)
                    .padding(.vertical, 8)
            }
            
            Divider()
            
            // Comment input
            HStack(spacing: 12) {
                TextField("Add a comment...", text: $viewModel.commentText, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(1...4)
                    .disabled(viewModel.isSubmitting)
                    .accessibilityLabel("Comment text field")
                
                Button(action: {
                    HapticFeedback.light()
                    Task {
                        await viewModel.submitComment(postId: post.id, authState: authState, onSuccess: {})
                    }
                }) {
                    if viewModel.isSubmitting {
                        ProgressView()
                            .frame(width: 32, height: 32)
                    } else {
                        ZStack {
                            Circle()
                                .fill(viewModel.commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? AnyShapeStyle(Color.gray.opacity(0.3)) : AnyShapeStyle(Color.purplePinkGradient))
                                .frame(width: 36, height: 36)
                            
                            Image(systemName: "arrow.up")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .shadow(color: viewModel.commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.clear : Color.primaryPurple.opacity(0.3), radius: 4, x: 0, y: 2)
                    }
                }
                .disabled(viewModel.commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isSubmitting)
            }
            .padding()
            .background(Color(.systemBackground))
        }
        .navigationTitle("Post Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    if post.author.id != authState.currentUser?.id {
                        Button(action: {
                            showReportPostDialog = true
                        }) {
                            Label("Report Post", systemImage: "exclamationmark.triangle")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .onAppear {
            Task {
                await viewModel.loadComments(postId: post.id, authState: authState)
            }
        }
        .refreshable {
            await viewModel.refreshComments(postId: post.id, authState: authState)
        }
        .confirmationDialog(
            "Delete Comment",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if let comment = viewModel.commentToDelete {
                    Task {
                        await viewModel.deleteComment(comment, postId: post.id, authState: authState)
                    }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete this comment?")
        }
        .alert("Report Post", isPresented: $showReportPostDialog) {
            TextField("Reason (optional)", text: $reportReason)
            Button("Report", role: .destructive) {
                Task {
                    await viewModel.reportPost(post: post, reason: reportReason.isEmpty ? nil : reportReason, authState: authState) {
                        reportSuccessMessage = "Post reported successfully"
                        showReportSuccessAlert = true
                        reportReason = ""
                    }
                }
            }
            Button("Cancel", role: .cancel) {
                reportReason = ""
            }
        } message: {
            Text("Report this post if it violates community guidelines. Provide an optional reason below.")
        }
        .alert("Report Comment", isPresented: $showReportCommentDialog) {
            TextField("Reason (optional)", text: $reportReason)
            Button("Report", role: .destructive) {
                if let comment = viewModel.commentToReport {
                    Task {
                        await viewModel.reportComment(comment, postId: post.id, reason: reportReason.isEmpty ? nil : reportReason, authState: authState) {
                            reportSuccessMessage = "Comment reported successfully"
                            showReportSuccessAlert = true
                            reportReason = ""
                        }
                    }
                }
            }
            Button("Cancel", role: .cancel) {
                reportReason = ""
            }
        } message: {
            Text("Report this comment if it violates community guidelines. Provide an optional reason below.")
        }
        .alert("Success", isPresented: $showReportSuccessAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(reportSuccessMessage)
        }
    }
}

// MARK: - Comment Row View

struct CommentRowView: View {
    let comment: Comment
    let isOwnComment: Bool
    var onDelete: () -> Void
    var onReport: () -> Void
    
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
                
                // Action buttons
                if isOwnComment {
                    // Delete button (only for own comments)
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .font(.caption)
                            .foregroundColor(.white)
                    }
                } else {
                    // Report button (only for others' comments)
                    Button(action: onReport) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.caption)
                            .foregroundColor(.primary)
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
    struct PreviewWrapper: View {
        @State private var post = Post(
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
        
        var body: some View {
            NavigationStack {
                PostDetailView(post: $post)
                    .environmentObject(AuthState())
            }
        }
    }
    
    return PreviewWrapper()
}
