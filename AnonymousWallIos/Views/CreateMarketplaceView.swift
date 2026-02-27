//
//  CreateMarketplaceView.swift
//  AnonymousWallIos
//
//  View for creating a new marketplace listing
//

import SwiftUI
import PhotosUI

struct CreateMarketplaceView: View {
    @EnvironmentObject var authState: AuthState
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = CreateMarketplaceViewModel()
    @State private var photoPickerItems: [PhotosPickerItem] = []

    var onCreated: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Wall selection
                    WallPickerSection(selectedWall: $viewModel.selectedWall)
                        .padding(.horizontal)
                        .padding(.top, 10)

                    // Required fields
                    requiredFieldsSection

                    // Optional fields
                    optionalFieldsSection

                    // Photos card
                    FormSectionCard(title: "Photos", systemIcon: "photo.on.rectangle.angled") {
                        if viewModel.canAddMoreImages {
                            let imageCount = viewModel.imageCount
                            let remainingSlots = viewModel.remainingImageSlots

                            PhotosPicker(
                                selection: $photoPickerItems,
                                maxSelectionCount: remainingSlots,
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
                                Task {
                                    var loadFailed = false
                                    for item in items {
                                        if let data = try? await item.loadTransferable(type: Data.self),
                                           let image = UIImage(data: data) {
                                            viewModel.addImage(image)
                                        } else {
                                            loadFailed = true
                                        }
                                    }
                                    photoPickerItems = []
                                    if loadFailed {
                                        viewModel.errorMessage = "One or more photos could not be loaded"
                                    }
                                }
                            }
                            .accessibilityLabel("Add photo")
                            .accessibilityHint("Double tap to select up to \(remainingSlots) photos")
                        }

                        if !viewModel.selectedImages.isEmpty {
                            ImageThumbnailStrip(images: viewModel.selectedImages) { index in
                                viewModel.removeImage(at: index)
                            }
                        }
                    }
                    .padding(.horizontal)

                    // Error message
                    if let errorMessage = viewModel.errorMessage {
                        FormErrorMessage(message: errorMessage)
                            .padding(.horizontal)
                    }

                    // Submit button
                    CreateFormSubmitButton(
                        icon: "tag.fill",
                        label: "List Item",
                        isLoading: viewModel.isPosting,
                        isDisabled: viewModel.isSubmitDisabled,
                        gradient: Color.orangePinkGradient,
                        action: {
                            HapticFeedback.light()
                            viewModel.createItem(authState: authState) {
                                onCreated()
                                dismiss()
                            }
                        }
                    )
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                    .accessibilityLabel("Submit listing")
                    .accessibilityHint(viewModel.isSubmitDisabled
                        ? "Complete required fields to list"
                        : "Double tap to list your item")
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("New Listing")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .accessibilityLabel("Cancel")
                        .accessibilityHint("Double tap to cancel creating a listing")
                }
            }
        }
    }

    @ViewBuilder
    private var requiredFieldsSection: some View {
        FormSectionCard(title: "Required", systemIcon: "asterisk.circle.fill") {
            StyledTextField(
                icon: "tag",
                label: "Title",
                placeholder: "e.g. Used Calculus Textbook",
                text: $viewModel.title,
                characterLimit: viewModel.maxTitleLength,
                accessibilityLabel: "Item title",
                accessibilityHint: "Required. Enter the item title"
            )

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 4) {
                    Image(systemName: "dollarsign.circle")
                        .font(.caption)
                        .foregroundColor(.primaryPurple)
                        .accessibilityHidden(true)
                    Text("Price ($)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                TextField("e.g. 45.99", text: $viewModel.priceText)
                    .keyboardType(.decimalPad)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(
                                (!viewModel.priceText.isEmpty && !viewModel.isPriceValid)
                                    ? Color.red : Color(.separator),
                                lineWidth: 0.5
                            )
                    )
                    .accessibilityLabel("Price in dollars")
                    .accessibilityHint("Required. Enter the item price")
                if !viewModel.priceText.isEmpty && !viewModel.isPriceValid {
                    Text("Please enter a valid price (0 or greater)")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
        }
        .padding(.horizontal)
    }

    @ViewBuilder
    private var optionalFieldsSection: some View {
        FormSectionCard(title: "Optional Details", systemIcon: "list.bullet.rectangle") {
            // Condition picker
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 4) {
                    Image(systemName: "sparkles")
                        .font(.caption)
                        .foregroundColor(.primaryPurple)
                        .accessibilityHidden(true)
                    Text("Condition")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                Picker("Condition", selection: $viewModel.selectedCondition) {
                    Text("Not specified").tag("")
                    ForEach(Array(zip(viewModel.validConditions, viewModel.conditionDisplayNames)), id: \.0) { value, display in
                        Text(display).tag(value)
                    }
                }
                .pickerStyle(.menu)
                .accessibilityLabel("Item condition")
            }

            // Category picker
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 4) {
                    Image(systemName: "square.grid.2x2")
                        .font(.caption)
                        .foregroundColor(.primaryPurple)
                        .accessibilityHidden(true)
                    Text("Category")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                Picker("Category", selection: $viewModel.selectedCategory) {
                    ForEach(MarketplaceCategory.allCases, id: \.self) { cat in
                        Label(cat.displayName, systemImage: cat.icon).tag(cat)
                    }
                }
                .pickerStyle(.menu)
                .accessibilityLabel("Item category")
            }

            StyledTextEditorField(
                icon: "text.alignleft",
                label: "Description",
                placeholder: "Describe your item…",
                text: $viewModel.description,
                characterLimit: viewModel.maxDescriptionLength,
                minHeight: 100,
                accessibilityLabel: "Description"
            )
        }
        .padding(.horizontal)
    }
}

#Preview {
    CreateMarketplaceView(onCreated: {})
        .environmentObject(AuthState())
}
