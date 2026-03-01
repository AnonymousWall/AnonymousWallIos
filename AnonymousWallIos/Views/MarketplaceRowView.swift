//
//  MarketplaceRowView.swift
//  AnonymousWallIos
//
//  Row view for displaying a single marketplace item
//

import SwiftUI

struct MarketplaceRowView: View {
    let item: MarketplaceItem
    let isOwnItem: Bool
    var onDelete: () -> Void
    var onTapAuthor: (() -> Void)?

    @EnvironmentObject var authState: AuthState
    @EnvironmentObject var blockViewModel: BlockViewModel
    @State private var showDeleteConfirmation = false
    @State private var selectedImageViewer: ImageViewerItem?
    @State private var showAuthorActionSheet = false
    @State private var showBlockSuccessAlert = false

    private var isCampus: Bool {
        item.wall.uppercased() == WallType.campus.rawValue.uppercased()
    }

    private var wallGradient: LinearGradient {
        LinearGradient.brandGradient
    }

    private var wallDisplayName: String {
        isCampus ? WallType.campus.displayName : WallType.national.displayName
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Wall badge and author
            HStack(spacing: 8) {
                Text(wallDisplayName)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(wallGradient)
                    .cornerRadius(12)
                    .accessibilityLabel("Posted on \(wallDisplayName) wall")

                Spacer()

                if isOwnItem {
                    Text("by Me")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.textSecondary)
                        .accessibilityLabel("Listed by you")
                } else {
                    Button(action: {
                        HapticFeedback.selection()
                        showAuthorActionSheet = true
                    }) {
                        Text("by \(item.author.profileName)")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.accentBlue)
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
                            onTapAuthor?()
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
            }

            // Title and price
            HStack(alignment: .top) {
                Text(item.title)
                    .font(.title3.bold())
                    .foregroundColor(.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityLabel("Item: \(item.title)")

                Spacer()

                Text(item.formattedPrice)
                    .font(.title3.bold())
                    .foregroundColor(.green)
                    .accessibilityLabel("Price: \(item.formattedPrice)")
            }

            // Details chips
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

            // Item images
            if !item.imageUrls.isEmpty {
                PostImageGallery(imageUrls: item.imageUrls, selectedImageViewer: $selectedImageViewer, accessibilityContext: "Item images")
            }

            // Footer
            HStack(spacing: 16) {
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

                // Comment count
                HStack(spacing: 5) {
                    Image(systemName: "bubble.left.fill")
                        .font(.callout)
                        .foregroundColor(.accentBlue)
                    Text("\(item.comments)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.accentBlue)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.accentBlue.opacity(0.15))
                .cornerRadius(8)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(item.comments) comments")

                // Delete button (own items only)
                if isOwnItem {
                    Button(action: {
                        HapticFeedback.warning()
                        showDeleteConfirmation = true
                    }) {
                        Image(systemName: "trash.fill")
                            .font(.callout)
                            .foregroundColor(.white)
                            .padding(6)
                            .background(Color.accentRed)
                            .cornerRadius(8)
                    }
                    .buttonStyle(.bounce)
                    .accessibilityLabel("Delete item")
                    .accessibilityHint("Double tap to delete this listing")
                    .confirmationDialog(
                        "Delete Item",
                        isPresented: $showDeleteConfirmation,
                        titleVisibility: .visible
                    ) {
                        Button("Delete", role: .destructive) { onDelete() }
                        Button("Cancel", role: .cancel) {}
                    } message: {
                        Text("Are you sure you want to delete this listing?")
                    }
                }
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
                .stroke(Color.surfaceSecondary, lineWidth: 0.5)
        )
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
    }

    // MARK: - Helpers
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
    MarketplaceRowView(
        item: MarketplaceItem(
            id: "1",
            title: "Used Calculus Textbook",
            price: 45.99,
            description: "Barely used, excellent condition",
            category: "books",
            condition: "like_new",
            wall: "CAMPUS",
            comments: 2,
            author: Post.Author(id: "user1", profileName: "John Doe", isAnonymous: false),
            createdAt: ISO8601DateFormatter().string(from: Date()),
            updatedAt: ISO8601DateFormatter().string(from: Date())
        ),
        isOwnItem: false,
        onDelete: {}
    )
    .padding()
    .environmentObject(AuthState())
    .environmentObject(BlockViewModel())
}