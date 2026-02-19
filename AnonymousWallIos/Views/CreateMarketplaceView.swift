//
//  CreateMarketplaceView.swift
//  AnonymousWallIos
//
//  View for creating a new marketplace listing
//

import SwiftUI

struct CreateMarketplaceView: View {
    @EnvironmentObject var authState: AuthState
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = CreateMarketplaceViewModel()

    var onCreated: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Wall selection
                    Picker("Wall", selection: $viewModel.selectedWall) {
                        ForEach(WallType.allCases, id: \.self) { wallType in
                            Text(wallType.displayName).tag(wallType)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                    .padding(.top, 10)
                    .accessibilityLabel("Select wall type")
                    .accessibilityValue(viewModel.selectedWall.displayName)
                    .onChange(of: viewModel.selectedWall) { _, _ in
                        HapticFeedback.selection()
                    }

                    // Required fields
                    requiredFieldsSection

                    // Optional fields
                    optionalFieldsSection

                    // Error message
                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                            .padding(.horizontal)
                    }

                    Spacer(minLength: 0)

                    // Submit button
                    Button(action: {
                        HapticFeedback.light()
                        viewModel.createItem(authState: authState) {
                            onCreated()
                            dismiss()
                        }
                    }) {
                        if viewModel.isPosting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .frame(maxWidth: .infinity)
                        } else {
                            HStack(spacing: 10) {
                                Image(systemName: "tag.fill").font(.body)
                                Text("List Item").fontWeight(.bold).font(.body)
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .frame(height: 56)
                    .background(
                        viewModel.isSubmitDisabled
                        ? AnyShapeStyle(Color.gray)
                        : AnyShapeStyle(Color.purplePinkGradient)
                    )
                    .foregroundColor(.white)
                    .cornerRadius(16)
                    .shadow(color: viewModel.isSubmitDisabled ? Color.clear : Color.primaryPurple.opacity(0.3), radius: 8, x: 0, y: 4)
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                    .disabled(viewModel.isSubmitDisabled)
                    .accessibilityLabel("Submit listing")
                    .accessibilityHint(viewModel.isSubmitDisabled ? "Complete required fields to list" : "Double tap to list your item")
                }
            }
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
        VStack(alignment: .leading, spacing: 16) {
            Text("Required")
                .font(.headline)
                .padding(.horizontal)
                .accessibilityAddTraits(.isHeader)

            // Title
            VStack(alignment: .leading, spacing: 6) {
                Text("Title")
                    .font(.subheadline).fontWeight(.medium)
                    .padding(.horizontal)
                TextField("e.g. Used Calculus Textbook", text: $viewModel.title)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                    .accessibilityLabel("Item title")
                    .accessibilityHint("Required. Enter the item title")
                HStack {
                    Spacer()
                    Text("\(viewModel.title.count)/\(viewModel.maxTitleLength)")
                        .font(.caption)
                        .foregroundColor(viewModel.isTitleOverLimit ? .red : .gray)
                }
                .padding(.horizontal)
            }

            // Price
            VStack(alignment: .leading, spacing: 6) {
                Text("Price ($)")
                    .font(.subheadline).fontWeight(.medium)
                    .padding(.horizontal)
                TextField("e.g. 45.99", text: $viewModel.priceText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.decimalPad)
                    .padding(.horizontal)
                    .accessibilityLabel("Price in dollars")
                    .accessibilityHint("Required. Enter the item price")
                if !viewModel.priceText.isEmpty && !viewModel.isPriceValid {
                    Text("Please enter a valid price (0 or greater)")
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                }
            }
        }
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
        .padding(.horizontal)
    }

    @ViewBuilder
    private var optionalFieldsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Optional")
                .font(.headline)
                .padding(.horizontal)
                .accessibilityAddTraits(.isHeader)

            // Condition picker
            VStack(alignment: .leading, spacing: 6) {
                Text("Condition")
                    .font(.subheadline).fontWeight(.medium)
                    .padding(.horizontal)
                Picker("Condition", selection: $viewModel.selectedCondition) {
                    Text("Not specified").tag("")
                    ForEach(Array(zip(viewModel.validConditions, viewModel.conditionDisplayNames)), id: \.0) { value, display in
                        Text(display).tag(value)
                    }
                }
                .pickerStyle(.menu)
                .padding(.horizontal)
                .accessibilityLabel("Item condition")
            }

            // Category
            VStack(alignment: .leading, spacing: 6) {
                Text("Category")
                    .font(.subheadline).fontWeight(.medium)
                    .padding(.horizontal)
                TextField("e.g. books, electronics, clothing", text: $viewModel.category)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                    .accessibilityLabel("Category")
            }

            // Description
            VStack(alignment: .leading, spacing: 6) {
                Text("Description")
                    .font(.subheadline).fontWeight(.medium)
                    .padding(.horizontal)
                HStack {
                    Spacer()
                    Text("\(viewModel.description.count)/\(viewModel.maxDescriptionLength)")
                        .font(.caption)
                        .foregroundColor(viewModel.isDescriptionOverLimit ? .red : .gray)
                }
                .padding(.horizontal)
                TextEditor(text: $viewModel.description)
                    .frame(minHeight: 100)
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .padding(.horizontal)
                    .accessibilityLabel("Description")
            }
        }
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
        .padding(.horizontal)
    }
}

#Preview {
    CreateMarketplaceView(onCreated: {})
        .environmentObject(AuthState())
}
