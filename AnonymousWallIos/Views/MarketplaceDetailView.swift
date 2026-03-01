//
//  MarketplaceDetailView.swift
//  AnonymousWallIos
//
//  Detail view for a marketplace item showing full info and comments
//

import SwiftUI

struct MarketplaceDetailView: View {
    @EnvironmentObject var authState: AuthState
    @Environment(\.dismiss) var dismiss

    @Binding var item: MarketplaceItem
    @StateObject private var viewModel = MarketplaceDetailViewModel()
    @State private var showDeleteConfirmation = false
    @State private var selectedImageViewer: ImageViewerItem?
    @State private var showAuthorActionSheet = false
    @State private var showBlockSuccessAlert = false
    @EnvironmentObject var blockViewModel: BlockViewModel

    var onTapAuthor: ((String, String) -> Void)?

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Item detail card
                    VStack(alignment: .leading, spacing: 14) {
                        // Author line
                        HStack {
                            if item.author.id == authState.currentUser?.id {
                                Text("Listed by Me")
                                    .font(.caption)
                                    .foregroundColor(.textSecondary)
                            } else {
                                Button(action: {
                                    HapticFeedback.selection()
                                    showAuthorActionSheet = true
                                }) {
                                    Text("Listed by \(item.author.profileName)")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(.blue)
                                        .underline()
                                }
                                .accessibilityLabel("Listed by \(item.author.profileName)")
                                .accessibilityHint("Double tap to message or block \(item.author.profileName)")
                                .confirmationDialog(
                                    item.author.profileName,
                                    isPresented: $showAuthorActionSheet,
                                    titleVisibility: .visible
                                ) {
                                    Button("Message \(item.author.profileName)") {
                                        onTapAuthor?(item.author.id, item.author.profileName)
                                    }
                                    Button("Block \(item.author.profileName)", role: .destructive) {
                                        HapticFeedback.warning()
                                        blockViewModel.blockUser(targetUserId: item.author.id, authState: authState) {
                                            showBlockSuccessAlert = true
                                        }
                                    }
                                    Button("Cancel", role: .cancel) {}
                                }
                            }
                            Spacer()
                        }

                        // Title and price
                        HStack(alignment: .top) {
                            Text(item.title)
                                .font(.title2.bold())
                                .foregroundColor(.textPrimary)
                                .fixedSize(horizontal: false, vertical: true)
                                .accessibilityLabel("Item: \(item.title)")

                            Spacer()

                            Text(item.formattedPrice)
                                .font(.title2.bold())
                                .foregroundColor(.green)
                                .accessibilityLabel("Price: \(item.formattedPrice)")
                        }

                        // Chips
                        HStack(spacing: 8) {
                            if let condition = item.condition, !condition.isEmpty {
                                let display = conditionDisplayName(condition)
                                Text(display)
                                    .font(.caption)
                                    .foregroundColor(.textSecondary)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.surfaceSecondary)
                                    .cornerRadius(8)
                                    .accessibilityLabel("Condition: \(display)")
                            }
                            if let category = item.category, !category.isEmpty {
                                Text(category.capitalized)
                                    .font(.caption)
                                    .foregroundColor(.textSecondary)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.surfaceSecondary)
                                    .cornerRadius(8)
                                    .accessibilityLabel("Category: \(category)")
                            }
                        }

                        // Description
                        if let description = item.description, !description.isEmpty {
                            Divider()
                            Text(description)
                                .font(.body)
                                .foregroundColor(.textPrimary)
                                .lineSpacing(2)
                                .fixedSize(horizontal: false, vertical: true)
                                .accessibilityLabel("Description: \(description)")
                        }

                        // Images
                        if !item.imageUrls.isEmpty {
                            PostImageGallery(imageUrls: item.imageUrls, selectedImageViewer: $selectedImageViewer, accessibilityContext: "Item images")
                        }

                        // Footer
                        HStack {
                            HStack(spacing: 4) {
                                Image(systemName: "clock")
                                    .font(.caption2)
                                    .foregroundColor(.textSecondary)
                                Text(DateFormatting.formatRelativeTime(item.createdAt))
                                    .font(.caption)
                                    .foregroundColor(.textSecondary)
                            }
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel("Posted \(DateFormatting.formatRelativeTime(item.createdAt))")

                            Spacer()

                            HStack(spacing: 5) {
                                Image(systemName: "bubble.left.fill")
                                    .font(.callout)
                                    .foregroundColor(.accentBlue)
                                Text("\(item.comments)")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.accentBlue)
                            }
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel("\(item.comments) comments")
                        }
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.surfacePrimary)
                            .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.borderSubtle, lineWidth: 0.5)
                    )

                    Divider().padding(.vertical, 8)

                    // Comments section
                    HStack {
                        Text("Comments")
                            .font(.headline)
                            .accessibilityAddTraits(.isHeader)

                        Spacer()

                        if !viewModel.comments.isEmpty {
                            Picker("Sort", selection: $viewModel.selectedSortOrder) {
                                Text(SortOrder.newest.displayName).tag(SortOrder.newest)
                                Text(SortOrder.oldest.displayName).tag(SortOrder.oldest)
                            }
                            .pickerStyle(.menu)
                            .accessibilityLabel("Sort comments")
                            .onChange(of: viewModel.selectedSortOrder) { _, _ in
                                viewModel.sortOrderChanged(itemId: item.id, authState: authState)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 8)

                    commentsList
                }
                .padding()
            }

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
                    viewModel.submitComment(itemId: item.id, authState: authState, item: $item, onSuccess: {})
                }) {
                    if viewModel.isSubmitting {
                        ProgressView().frame(width: 32, height: 32)
                    } else {
                        ZStack {
                            Circle()
                                .fill(viewModel.commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                      ? AnyShapeStyle(Color.gray.opacity(0.3))
                                      : AnyShapeStyle(LinearGradient.brandGradient))
                                .frame(width: 36, height: 36)
                            Image(systemName: "arrow.up")
                                .font(.callout.bold())
                                .foregroundColor(.white)
                        }
                    }
                }
                .disabled(viewModel.commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isSubmitting)
                .accessibilityLabel("Submit comment")
                .accessibilityHint("Double tap to post your comment")
            }
            .padding()
            .background(Color.surfacePrimary)
        }
        .navigationTitle("Item Details")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color.appBackground.ignoresSafeArea())
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    if item.author.id == authState.currentUser?.id {
                        Button(role: .destructive, action: { showDeleteConfirmation = true }) {
                            Label("Delete Item", systemImage: "trash")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .accessibilityLabel("Item options")
                }
            }
        }
        .onAppear {
            viewModel.loadComments(itemId: item.id, authState: authState)
        }
        .refreshable {
            await viewModel.refreshComments(itemId: item.id, authState: authState)
        }
        .confirmationDialog(
            "Delete Item",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                viewModel.deleteItem(item: item, authState: authState) {
                    dismiss()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete this listing?")
        }
        .confirmationDialog(
            "Delete Comment",
            isPresented: Binding(
                get: { viewModel.commentToDelete != nil },
                set: { if !$0 { viewModel.commentToDelete = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if let comment = viewModel.commentToDelete {
                    viewModel.deleteComment(comment, itemId: item.id, authState: authState, item: $item)
                    viewModel.commentToDelete = nil
                }
            }
            Button("Cancel", role: .cancel) { viewModel.commentToDelete = nil }
        } message: {
            Text("Are you sure you want to delete this comment?")
        }
        .fullScreenCover(item: $selectedImageViewer) { viewer in
            FullScreenImageViewer(imageURLs: item.imageUrls, initialIndex: viewer.index)
        }
        .alert("User Blocked", isPresented: $showBlockSuccessAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("\(item.author.profileName) has been blocked.")
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
        .onReceive(blockViewModel.userBlockedPublisher) { blockedUserId in
            viewModel.removeCommentsFromUser(blockedUserId)
        }
    }

    @ViewBuilder
    private var commentsList: some View {
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
                        },
                        onReport: {},
                        onTapAuthor: {
                            onTapAuthor?(comment.author.id, comment.author.profileName)
                        }
                    )
                    .onAppear {
                        viewModel.loadMoreCommentsIfNeeded(for: comment, itemId: item.id, authState: authState)
                    }
                }

                if viewModel.isLoadingMoreComments {
                    HStack {
                        Spacer()
                        ProgressView().padding()
                        Spacer()
                    }
                }
            }
        }
    }

    private func conditionDisplayName(_ condition: String) -> String {
        switch condition {
        case "new": return "New"
        case "like-new": return "Like New"
        case "good": return "Good"
        case "fair": return "Fair"
        default: return condition.replacingOccurrences(of: "-", with: " ").capitalized
        }
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var item = MarketplaceItem(
            id: "1",
            title: "Used Calculus Textbook",
            price: 45.99,
            description: "Barely used, excellent condition. Includes all problem sets.",
            category: "books",
            condition: "like_new",
            wall: "CAMPUS",
            comments: 2,
            author: Post.Author(id: "user1", profileName: "John Doe", isAnonymous: false),
            createdAt: ISO8601DateFormatter().string(from: Date()),
            updatedAt: ISO8601DateFormatter().string(from: Date())
        )

        var body: some View {
            NavigationStack {
                MarketplaceDetailView(item: $item)
                    .environmentObject(AuthState())
                    .environmentObject(BlockViewModel())
            }
        }
    }
    return PreviewWrapper()
}
