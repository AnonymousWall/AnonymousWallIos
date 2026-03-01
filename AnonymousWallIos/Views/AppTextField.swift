//
//  AppTextField.swift
//  AnonymousWallIos
//
//  Styled single-line text input using design system tokens.
//

import SwiftUI

struct AppTextField: View {
    let placeholder: String
    var icon: String? = nil
    @Binding var text: String
    var characterLimit: Int? = nil
    var keyboardType: UIKeyboardType = .default
    var isSecure: Bool = false
    var accessibilityLabel: String? = nil

    @FocusState private var isFocused: Bool

    // Counts extended grapheme clusters (user-perceived characters).
    // If the backend uses a different unit (e.g. UTF-16 code units), switch to text.utf16.count.
    private var isOverLimit: Bool {
        guard let limit = characterLimit else { return false }
        return text.count > limit
    }

    var body: some View {
        VStack(alignment: .trailing, spacing: 0) {
            HStack(spacing: Spacing.md) {
                if let icon {
                    Image(systemName: icon)
                        .font(.body)
                        .foregroundColor(isFocused ? .accentPurple : .textSecondary)
                        .frame(width: 20)
                        .accessibilityHidden(true)
                }
                if isSecure {
                    SecureField(placeholder, text: $text)
                        .focused($isFocused)
                        .autocorrectionDisabled()
                        .font(.bodyMedium)
                        .foregroundColor(.textPrimary)
                } else {
                    TextField(placeholder, text: $text)
                        .focused($isFocused)
                        .keyboardType(keyboardType)
                        .autocorrectionDisabled()
                        .font(.bodyMedium)
                        .foregroundColor(.textPrimary)
                }
                if let limit = characterLimit {
                    Text("\(text.count)/\(limit)")
                        .font(.captionFont)
                        .foregroundColor(isOverLimit ? .accentRed : .textTertiary)
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.md)
            .background(Color.surfaceSecondary)
            .cornerRadius(Radius.md)
            .overlay(
                RoundedRectangle(cornerRadius: Radius.md)
                    .stroke(
                        isOverLimit ? Color.accentRed : (isFocused ? Color.borderMedium : Color.borderSubtle),
                        lineWidth: 1
                    )
            )
        }
        .accessibilityLabel(accessibilityLabel ?? placeholder)
    }
}

#Preview {
    VStack(spacing: 16) {
        AppTextField(placeholder: "Email address", icon: "envelope", text: .constant(""))
        AppTextField(placeholder: "Password", icon: "lock", text: .constant(""), isSecure: true)
        AppTextField(placeholder: "Title", text: .constant("Hello"), characterLimit: 100)
    }
    .padding()
    .background(Color.appBackground)
}
