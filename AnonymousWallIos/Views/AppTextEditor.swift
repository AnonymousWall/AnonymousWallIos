//
//  AppTextEditor.swift
//  AnonymousWallIos
//
//  Styled multiline text editor using design system tokens.
//

import SwiftUI

struct AppTextEditor: View {
    let placeholder: String
    @Binding var text: String
    var characterLimit: Int? = nil
    var minHeight: CGFloat = 120
    var accessibilityLabel: String? = nil

    @FocusState private var isFocused: Bool

    // Counts extended grapheme clusters (user-perceived characters).
    // If the backend uses a different unit (e.g. UTF-16 code units), switch to text.utf16.count.
    private var isOverLimit: Bool {
        guard let limit = characterLimit else { return false }
        return text.count > limit
    }

    var body: some View {
        VStack(alignment: .trailing, spacing: Spacing.xs) {
            ZStack(alignment: .topLeading) {
                TextEditor(text: $text)
                    .focused($isFocused)
                    .frame(minHeight: minHeight)
                    .padding(Spacing.sm)
                    .font(.bodyMedium)
                    .foregroundColor(.textPrimary)
                    .scrollContentBackground(.hidden)
                    .background(Color.surfaceSecondary)
                    .cornerRadius(Radius.md)
                    .overlay(
                        RoundedRectangle(cornerRadius: Radius.md)
                            .stroke(
                                isOverLimit ? Color.accentRed : (isFocused ? Color.borderMedium : Color.borderSubtle),
                                lineWidth: 1
                            )
                    )

                if text.isEmpty {
                    Text(placeholder)
                        .font(.bodyMedium)
                        .foregroundColor(.textTertiary)
                        .padding(.horizontal, Spacing.md)
                        .padding(.vertical, Spacing.md)
                        .allowsHitTesting(false)
                }
            }

            if let limit = characterLimit {
                Text("\(text.count)/\(limit)")
                    .font(.captionFont)
                    .foregroundColor(isOverLimit ? .accentRed : .textTertiary)
            }
        }
        .accessibilityLabel(accessibilityLabel ?? placeholder)
    }
}

#Preview {
    AppTextEditor(placeholder: "What's on your mind?", text: .constant(""))
        .padding()
        .background(Color.appBackground)
}
