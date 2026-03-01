//
//  FormComponents.swift
//  AnonymousWallIos
//
//  Shared reusable form UI components for Create Post, Internship, and Marketplace forms.
//  Extracted to eliminate duplication and ensure consistent styling across all creation flows.
//

import SwiftUI

// MARK: - Wall Picker Section

/// Segmented control for selecting campus vs. national wall – shared by all create forms.
struct WallPickerSection: View {
    @Binding var selectedWall: WallType

    var body: some View {
        Picker("Wall", selection: $selectedWall) {
            ForEach(WallType.allCases, id: \.self) { wallType in
                Text(wallType.displayName).tag(wallType)
            }
        }
        .pickerStyle(.segmented)
        .accessibilityLabel("Select wall type")
        .accessibilityValue(selectedWall.displayName)
        .onChange(of: selectedWall) { _, _ in
            HapticFeedback.selection()
        }
    }
}

// MARK: - Form Section Card

/// Card container for a logical group of form fields, with a titled header and icon.
struct FormSectionCard<Content: View>: View {
    let title: String
    let systemIcon: String
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: systemIcon)
                    .font(.callout)
                    .foregroundColor(.accentPurple)
                    .accessibilityHidden(true)
                Text(title)
                    .font(.headline)
            }
            .accessibilityAddTraits(.isHeader)

            content()
        }
        .padding(16)
        .background(Color.surfacePrimary)
        .cornerRadius(16)
    }
}

// MARK: - Styled Text Field

/// A consistently styled single-line text field with an icon label and an optional character counter.
struct StyledTextField: View {
    let icon: String
    let label: String
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var characterLimit: Int? = nil
    var accessibilityLabel: String? = nil
    var accessibilityHint: String? = nil

    private var isOverLimit: Bool {
        guard let limit = characterLimit else { return false }
        return text.count > limit
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(.accentPurple)
                    .accessibilityHidden(true)
                Text(label)
                    .font(.subheadline)
                    .fontWeight(.medium)
                if let limit = characterLimit {
                    Spacer()
                    Text("\(text.count)/\(limit)")
                        .font(.caption2)
                        .foregroundColor(isOverLimit ? .accentRed : .textSecondary)
                }
            }
            TextField(placeholder, text: $text)
                .keyboardType(keyboardType)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color.surfaceSecondary)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isOverLimit ? Color.accentRed : Color.borderSubtle, lineWidth: 0.5)
                )
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel ?? label)
        .accessibilityHint(accessibilityHint ?? "")
    }
}

// MARK: - Styled Text Editor

/// A consistently styled multi-line text editor with an icon label and an optional character counter.
struct StyledTextEditorField: View {
    let icon: String
    let label: String
    let placeholder: String
    @Binding var text: String
    var characterLimit: Int? = nil
    var minHeight: CGFloat = 120
    var accessibilityLabel: String? = nil

    private var isOverLimit: Bool {
        guard let limit = characterLimit else { return false }
        return text.count > limit
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(.accentPurple)
                    .accessibilityHidden(true)
                Text(label)
                    .font(.subheadline)
                    .fontWeight(.medium)
                if let limit = characterLimit {
                    Spacer()
                    Text("\(text.count)/\(limit)")
                        .font(.caption2)
                        .foregroundColor(isOverLimit ? .accentRed : .textSecondary)
                }
            }
            ZStack(alignment: .topLeading) {
                TextEditor(text: $text)
                    .frame(minHeight: minHeight)
                    .padding(8)
                    .background(Color.surfaceSecondary)
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(isOverLimit ? Color.accentRed : Color.borderSubtle, lineWidth: 0.5)
                    )
                if text.isEmpty {
                    Text(placeholder)
                        .foregroundColor(Color(.placeholderText))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 14)
                        .allowsHitTesting(false)
                }
            }
        }
        .accessibilityLabel(accessibilityLabel ?? label)
    }
}

// MARK: - Create Form Submit Button

/// Gradient submit button with a loading spinner, shared by all create forms.
struct CreateFormSubmitButton: View {
    let icon: String
    let label: String
    let isLoading: Bool
    let isDisabled: Bool
    let gradient: LinearGradient
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Group {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    HStack(spacing: 10) {
                        Image(systemName: icon).font(.body)
                        Text(label).fontWeight(.semibold).font(.body)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
        }
        .background {
            if isDisabled {
                Color.gray
            } else {
                gradient
            }
        }
        .foregroundColor(.white)
        .cornerRadius(16)
        .shadow(color: isDisabled ? .clear : Color.accentPurple.opacity(0.3), radius: 8, x: 0, y: 4)
        .disabled(isDisabled || isLoading)
    }
}

// MARK: - Form Error Message

/// Inline styled error banner for form validation feedback.
struct FormErrorMessage: View {
    let message: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.caption)
                .foregroundColor(.accentRed)
                .accessibilityHidden(true)
            Text(message)
                .font(.caption)
                .foregroundColor(.accentRed)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.accentRed.opacity(0.08))
        .cornerRadius(10)
        .accessibilityLabel("Error: \(message)")
    }
}

// MARK: - Image Thumbnail Strip

/// Horizontal scrolling row of selected image thumbnails with per-image remove buttons.
struct ImageThumbnailStrip: View {
    let images: [UIImage]
    let onRemove: (Int) -> Void

    private static let removeButtonBackgroundOpacity: Double = 0.5

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(images.indices, id: \.self) { index in
                    ZStack(alignment: .topTrailing) {
                        Image(uiImage: images[index])
                            .resizable()
                            .scaledToFill()
                            .frame(width: 80, height: 80)
                            .clipped()
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color(.separator), lineWidth: 0.5)
                            )
                        Button {
                            onRemove(index)
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title3)
                                .foregroundStyle(.white, Color.black.opacity(Self.removeButtonBackgroundOpacity))
                        }
                        .padding(4)
                        .accessibilityLabel("Remove image \(index + 1)")
                    }
                }
            }
            .padding(.vertical, 4)
        }
        .accessibilityLabel("Selected images, \(images.count) of 5")
    }
}
