//
//  CreatePostView.swift
//  AnonymousWallIos
//
//  View for creating a new post
//

import SwiftUI
import PhotosUI

struct CreatePostView: View {
    @EnvironmentObject var authState: AuthState
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = CreatePostViewModel()
    @State private var photoPickerItems: [PhotosPickerItem] = []

    var onPostCreated: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Wall selection
                    WallPickerSection(selectedWall: $viewModel.selectedWall)
                        .padding(.horizontal)
                        .padding(.top, 10)

                    // Post type toggle
                    PostTypePickerSection(postType: $viewModel.postType)
                        .padding(.horizontal)

                    // Post details card
                    FormSectionCard(title: "Post Details", systemIcon: "doc.text.fill") {
                        StyledTextField(
                            icon: "character.cursor.ibeam",
                            label: "Title",
                            placeholder: "Enter post title",
                            text: $viewModel.postTitle,
                            characterLimit: viewModel.maxTitleCount,
                            accessibilityLabel: "Post title",
                            accessibilityHint: "Enter the title for your post"
                        )

                        StyledTextEditorField(
                            icon: "text.alignleft",
                            label: viewModel.isPollMode ? "Context (optional)" : "Content",
                            placeholder: viewModel.isPollMode ? "Add context (optional)" : "What's on your mind?",
                            text: $viewModel.postContent,
                            characterLimit: viewModel.maxContentCount,
                            minHeight: viewModel.isPollMode ? 80 : 180,
                            accessibilityLabel: viewModel.isPollMode ? "Poll context (optional)" : "Post content"
                        )
                    }
                    .padding(.horizontal)

                    // Poll options editor (only in poll mode)
                    if viewModel.isPollMode {
                        FormSectionCard(title: "Poll Options", systemIcon: "list.bullet.rectangle") {
                            PollOptionsEditorView(
                                pollOptions: $viewModel.pollOptions,
                                maxCharacters: viewModel.maxPollOptionCount,
                                canAdd: viewModel.canAddPollOption,
                                canRemove: viewModel.canRemovePollOption,
                                onAdd: { viewModel.addPollOption() },
                                onRemove: { viewModel.removePollOption(at: $0) }
                            )
                        }
                        .padding(.horizontal)
                    }

                    // Photos card (only for standard posts)
                    if !viewModel.isPollMode {
                        FormSectionCard(title: "Photos", systemIcon: "photo.on.rectangle.angled") {
                            if viewModel.canAddMoreImages {
                                let imageCount = viewModel.imageCount
                                PhotosPicker(
                                    selection: $photoPickerItems,
                                    maxSelectionCount: viewModel.remainingImageSlots,
                                    matching: .images
                                ) {
                                    HStack {
                                        Image(systemName: "plus.circle.fill")
                                            .foregroundColor(.primaryPurple)
                                        Text("Add Photo (\(imageCount)/5)")
                                            .foregroundColor(.primaryPurple)
                                            .fontWeight(.medium)
                                        Spacer()
                                    }
                                    .padding(.vertical, 4)
                                }
                                .onChange(of: photoPickerItems) { _, items in
                                    guard !items.isEmpty else { return }
                                    Task {
                                        await viewModel.loadPhotos(items)
                                        photoPickerItems = []
                                    }
                                }
                                .accessibilityLabel("Add photo")
                                .accessibilityHint("Double tap to select up to \(viewModel.remainingImageSlots) photos")
                            }

                            if viewModel.isLoadingImages {
                                VStack(spacing: 6) {
                                    ProgressView(value: viewModel.imageLoadProgress)
                                        .tint(.primaryPurple)
                                    Text(viewModel.imageLoadProgress < 1.0
                                        ? "Downloading from iCloud... \(Int(viewModel.imageLoadProgress * 100))%"
                                        : "Processing...")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.vertical, 4)
                                .transition(.opacity)
                            }

                            if !viewModel.selectedImages.isEmpty {
                                ImageThumbnailStrip(images: viewModel.selectedImages) { index in
                                    viewModel.removeImage(at: index)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }

                    // Error message
                    if let errorMessage = viewModel.errorMessage {
                        FormErrorMessage(message: errorMessage)
                            .padding(.horizontal)
                    }

                    // Submit button
                    CreateFormSubmitButton(
                        icon: "paperplane.fill",
                        label: "Post",
                        isLoading: viewModel.isPosting,
                        isDisabled: viewModel.isPostButtonDisabled,
                        gradient: Color.purplePinkGradient,
                        action: {
                            HapticFeedback.light()
                            viewModel.createPost(authState: authState, onSuccess: {
                                onPostCreated()
                                dismiss()
                            })
                        }
                    )
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                    .accessibilityLabel("Submit post")
                    .accessibilityHint(viewModel.isPostButtonDisabled
                        ? "Complete the required fields to post"
                        : "Double tap to create your post")
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("New Post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .accessibilityLabel("Cancel")
                    .accessibilityHint("Double tap to cancel creating a post")
                }
            }
        }
    }
}

// MARK: - Post Type Picker

private struct PostTypePickerSection: View {
    @Binding var postType: PostType

    var body: some View {
        Picker("Post Type", selection: $postType) {
            Text("Standard").tag(PostType.standard)
            Text("Poll").tag(PostType.poll)
        }
        .pickerStyle(.segmented)
        .accessibilityLabel("Select post type")
        .accessibilityValue(postType == .poll ? "Poll" : "Standard")
        .onChange(of: postType) { _, _ in
            HapticFeedback.selection()
        }
    }
}

#Preview {
    CreatePostView(onPostCreated: {})
        .environmentObject(AuthState())
}
