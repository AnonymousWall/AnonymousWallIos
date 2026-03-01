//
//  PostDetailView.swift
//  AnonymousWallIos
//
//  Detail view for a post showing comments
//

import SwiftUI

struct PostDetailView: View {
    @EnvironmentObject var authState: AuthState
    @EnvironmentObject var blockViewModel: BlockViewModel
    @Environment(\.dismiss) var dismiss
    
    @Binding var post: Post
    @StateObject private var viewModel = PostDetailViewModel()
    @State private var showDeleteConfirmation = false
    @State private var showReportPostDialog = false
    @State private var showReportCommentDialog = false
    @State private var reportReason = ""
    @State private var showReportSuccessAlert = false
    @State private var reportSuccessMessage = ""
    @State private var selectedImageViewer: ImageViewerItem?
    
    var onTapAuthor: ((String, String) -> Void)?
    
    var body: some View {
        VStack(spacing: 0) {
            // Post content
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Original post
                    AppCard {
                        VStack(alignment: .leading, spacing: 14) {
                            // Post title
                            Text(post.title)
                                .font(.displayMedium)
                                .foregroundColor(.textPrimary)
                                .fixedSize(horizontal: false, vertical: true)
                                .accessibilityLabel("Post title: \(post.title)")
                            
                            Text(post.content)
                                .font(.bodyMedium)
                                .foregroundColor(.textSecondary)
                                .lineSpacing(2)
                                .fixedSize(horizontal: false, vertical: true)
                                .accessibilityLabel("Post content: \(post.content)")
                            
                            // Poll card (poll posts only)
                            if post.postType?.lowercased() == "poll",
                               let poll = post.poll,
                               let postUUID = UUID(uuidString: post.id) {
                                PollCardView(postId: postUUID, poll: poll)
                            }
                            
                            // Post images
                            if !post.imageUrls.isEmpty {
                                PostImageGallery(imageUrls: post.imageUrls, selectedImageViewer: $selectedImageViewer, accessibilityContext: "Post images")
                            }
                            
                            HStack(spacing: 16) {
                                HStack(spacing: 4) {
                                    Image(systemName: "clock")
                                        .font(.caption2)
                                        .foregroundColor(.textTertiary)
                                    Text(DateFormatting.formatRelativeTime(post.createdAt))
                                        .font(.caption)
                                        .foregroundColor(.textTertiary)
                                }
                                .accessibilityElement(children: .combine)
                                .accessibilityLabel("Posted \(DateFormatting.formatRelativeTime(post.createdAt))")
                                
                                Spacer()
                                
                                HStack(spacing: 16) {
                                    // Like button
                                    Button(action: {
                                        HapticFeedback.medium()
                                        viewModel.toggleLike(post: $post, authState: authState)
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
                                        .background(post.liked ? Color.pink.opacity(0.15) : Color.surfaceSecondary)
                                        .cornerRadius(8)
                                    }
                                    .buttonStyle(.bounce)
                                    .accessibilityLabel(post.liked ? "Unlike" : "Like")
                                    .accessibilityValue("\(post.likes) likes")
                                    .accessibilityHint(post.liked ? "Double tap to remove your like" : "Double tap to like this post")
                                    
                                    HStack(spacing: 5) {
                                        Image(systemName: "bubble.left.fill")
                                            .font(.callout)
                                            .foregroundColor(.accentBlue)
                                        Text("\(post.comments)")
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.accentBlue)
                                    }
                                    .accessibilityElement(children: .combine)
                                    .accessibilityLabel("\(post.comments) comments")
                                }
                            }
                        }
                    }
                    
                    Divider()
                        .padding(.vertical, 8)
                    
                    // Comments section header with sorting
                    HStack {
                        SectionLabel(text: "Comments")
                        
                        Spacer()
                        
                        // Sort order picker for comments
                        if !viewModel.comments.isEmpty {
                            Picker("Sort", selection: $viewModel.selectedSortOrder) {
                                Text("Newest").tag(SortOrder.newest)
                                Text("Oldest").tag(SortOrder.oldest)
                            }
                            .pickerStyle(.menu)
                            .accessibilityLabel("Sort comments")
                            .onChange(of: viewModel.selectedSortOrder) { _, _ in
                                viewModel.sortOrderChanged(postId: post.id, authState: authState)
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
                                .font(.largeTitle)
                                .foregroundColor(.textSecondary)
                                .accessibilityHidden(true)
                            Text("No comments yet")
                                .font(.subheadline)
                                .foregroundColor(.textSecondary)
                            Text("Be the first to comment!")
                                .font(.caption)
                                .foregroundColor(.textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 32)
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("No comments yet. Be the first to comment!")
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
                                    },
                                    onTapAuthor: {
                                        onTapAuthor?(comment.author.id, comment.author.profileName)
                                    }
                                )
                                .onAppear {
                                    // Load more when the last comment appears
                                    viewModel.loadMoreCommentsIfNeeded(for: comment, postId: post.id, authState: authState)
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
                    .foregroundColor(.accentRed)
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
                    .accessibilityHint("Enter your comment here")
                
                Button(action: {
                    HapticFeedback.light()
                    viewModel.submitComment(postId: post.id, authState: authState, post: $post, onSuccess: {})
                }) {
                    if viewModel.isSubmitting {
                        ProgressView()
                            .frame(width: 32, height: 32)
                    } else {
                        ZStack {
                            Circle()
                                .fill(viewModel.commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? AnyShapeStyle(Color.gray.opacity(0.3)) : AnyShapeStyle(LinearGradient.brandGradient))
                                .frame(width: 36, height: 36)
                            
                            Image(systemName: "arrow.up")
                                .font(.callout.bold())
                                .foregroundColor(.white)
                        }
                        .shadow(color: viewModel.commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.clear : Color.accentPurple.opacity(0.3), radius: 4, x: 0, y: 2)
                    }
                }
                .disabled(viewModel.commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isSubmitting)
                .accessibilityLabel("Submit comment")
                .accessibilityHint("Double tap to post your comment")
            }
            .padding()
            .background(Color.surfacePrimary)
        }
        .background(Color.appBackground.ignoresSafeArea())
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
                        .accessibilityLabel("Post options")
                }
            }
        }
        .onAppear {
            viewModel.loadComments(postId: post.id, authState: authState)
            viewModel.refreshPost(post: $post, authState: authState)
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
                    viewModel.deleteComment(comment, postId: post.id, authState: authState, post: $post)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete this comment?")
        }
        .alert("Report Post", isPresented: $showReportPostDialog) {
            TextField("Reason (optional)", text: $reportReason)
            Button("Report", role: .destructive) {
                viewModel.reportPost(post: post, reason: reportReason.isEmpty ? nil : reportReason, authState: authState) {
                    reportSuccessMessage = "Post reported successfully"
                    showReportSuccessAlert = true
                    reportReason = ""
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
                    viewModel.reportComment(comment, postId: post.id, reason: reportReason.isEmpty ? nil : reportReason, authState: authState) {
                        reportSuccessMessage = "Comment reported successfully"
                        showReportSuccessAlert = true
                        reportReason = ""
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
        .fullScreenCover(item: $selectedImageViewer) { item in
            FullScreenImageViewer(imageURLs: post.imageUrls, initialIndex: item.index)
        }
        .onReceive(blockViewModel.userBlockedPublisher) { blockedUserId in
            viewModel.removeCommentsFromUser(blockedUserId)
        }
    }
}

// MARK: - Comment Row View

struct CommentRowView: View {
    @EnvironmentObject var authState: AuthState
    @EnvironmentObject var blockViewModel: BlockViewModel
    let comment: Comment
    let isOwnComment: Bool
    var onDelete: () -> Void
    var onReport: () -> Void
    var onTapAuthor: (() -> Void)?

    @State private var showAuthorActionSheet = false
    @State private var showBlockSuccessAlert = false

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
                    if isOwnComment {
                        Text("Me")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .accessibilityLabel("Your comment")
                    } else {
                        Button(action: {
                            HapticFeedback.selection()
                            showAuthorActionSheet = true
                        }) {
                            Text(comment.author.profileName)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .underline()
                        }
                        .accessibilityLabel("Comment by \(comment.author.profileName)")
                        .accessibilityHint("Double tap to message or block \(comment.author.profileName)")
                        .confirmationDialog(
                            comment.author.profileName,
                            isPresented: $showAuthorActionSheet,
                            titleVisibility: .visible
                        ) {
                            Button("Message \(comment.author.profileName)") {
                                onTapAuthor?()
                            }
                            Button("Block \(comment.author.profileName)", role: .destructive) {
                                HapticFeedback.warning()
                                blockViewModel.blockUser(targetUserId: comment.author.id, authState: authState) {
                                    showBlockSuccessAlert = true
                                }
                            }
                            Button("Cancel", role: .cancel) {}
                        }
                    }
                    
                    Text(comment.text)
                        .font(.body)
                        .foregroundColor(isOwnComment ? .white : .textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityLabel("Comment: \(comment.text)")
                    
                    Text(DateFormatting.formatRelativeTime(comment.createdAt))
                        .font(.caption2)
                        .foregroundColor(isOwnComment ? Color.white.opacity(0.8) : .gray)
                        .accessibilityLabel("Posted \(DateFormatting.formatRelativeTime(comment.createdAt))")
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
                    .accessibilityLabel("Delete comment")
                    .accessibilityHint("Double tap to delete this comment")
                } else {
                    // Report button (only for others' comments)
                    Button(action: onReport) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.caption)
                            .foregroundColor(.textPrimary)
                    }
                    .accessibilityLabel("Report comment")
                    .accessibilityHint("Double tap to report this comment")
                }
            }
            .padding()
            .background(
                Group {
                    if isOwnComment {
                        AnyShapeStyle(LinearGradient.brandGradient)
                    } else {
                        AnyShapeStyle(Color.surfaceSecondary)
                    }
                }
            )
            .cornerRadius(8)
            
            // Add trailing spacer for other users' comments (push to left)
            if !isOwnComment {
                Spacer()
                    .frame(minWidth: 40)
            }
        }
        .padding(.horizontal)
        .alert("User Blocked", isPresented: $showBlockSuccessAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("\(comment.author.profileName) has been blocked.")
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
                    .environmentObject(BlockViewModel())
            }
        }
    }
    
    return PreviewWrapper()
}
