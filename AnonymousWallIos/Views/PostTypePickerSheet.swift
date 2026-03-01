//
//  PostTypePickerSheet.swift
//  AnonymousWallIos
//
//  Bottom sheet for selecting a post type in CreatePostView
//

import SwiftUI

// MARK: - Coming Soon Post Type

/// Represents a placeholder post type that is not yet available.
struct ComingSoonPostType {
    let icon: String
    let name: String
    let description: String

    static let all: [ComingSoonPostType] = [
        ComingSoonPostType(icon: "calendar", name: "Event", description: "Organize meetups and campus events"),
        ComingSoonPostType(icon: "questionmark.bubble", name: "Question", description: "Ask for advice or recommendations")
    ]
}

// MARK: - PostTypePickerSheet

struct PostTypePickerSheet: View {
    @Binding var selectedType: PostType
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Sheet title
            SectionLabel(text: "Post Type")
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.top, 20)
                .padding(.bottom, 12)

            // Selectable post types
            ForEach(PostType.allCases, id: \.self) { type in
                PostTypeRow(type: type, isSelected: selectedType == type) {
                    selectedType = type
                    HapticFeedback.selection()
                    Task {
                        try? await Task.sleep(for: .seconds(0.15))
                        dismiss()
                    }
                }
            }

            // Coming soon rows
            ForEach(ComingSoonPostType.all, id: \.name) { item in
                ComingSoonTypeRow(icon: item.icon, name: item.name, description: item.description)
            }

            Spacer()
        }
        .background(Color.surfacePrimary)
    }
}

// MARK: - PostTypeRow

struct PostTypeRow: View {
    let type: PostType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                // Icon container
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(type.accentColor.opacity(0.12))
                        .frame(width: 44, height: 44)
                    Image(systemName: type.icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(type.accentColor)
                }

                // Name + description
                VStack(alignment: .leading, spacing: 2) {
                    Text(type.displayName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.textPrimary)
                    Text(type.description)
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                        .lineLimit(2)
                }

                Spacer()

                // Checkmark
                if isSelected {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [type.accentColor, type.accentColor.opacity(0.7)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 24, height: 24)
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
            .padding(.horizontal, 16)
            .frame(minHeight: 56)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(type.displayName). \(type.description)")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

// MARK: - ComingSoonTypeRow

private struct ComingSoonTypeRow: View {
    let icon: String
    let name: String
    let description: String

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.secondary.opacity(0.12))
                    .frame(width: 44, height: 44)
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.secondary)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.textPrimary)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.textSecondary)
                    .lineLimit(2)
            }

            Spacer()

            Text("Soon")
                .font(.caption2.weight(.semibold))
                .foregroundColor(.textSecondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule().fill(Color.surfaceSecondary)
                )
        }
        .padding(.horizontal, 16)
        .frame(minHeight: 56)
        .opacity(0.4)
        .accessibilityLabel("\(name). Coming soon.")
        .accessibilityAddTraits(.isStaticText)
    }
}

#Preview {
    PostTypePickerSheet(selectedType: .constant(.standard))
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(28)
}
