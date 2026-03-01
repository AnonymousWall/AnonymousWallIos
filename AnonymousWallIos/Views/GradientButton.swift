//
//  GradientButton.swift
//  AnonymousWallIos
//
//  Primary action button with brand gradient background.
//

import SwiftUI

struct GradientButton: View {
    let label: String?
    var icon: String? = nil
    var isLoading: Bool = false
    var isDisabled: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Group {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    HStack(spacing: Spacing.sm) {
                        if let icon {
                            Image(systemName: icon)
                                .font(.body.weight(.semibold))
                        }
                        if let label {
                            Text(label)
                                .font(.labelLarge)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .foregroundColor(.white)
        }
        .background(isDisabled ? AnyShapeStyle(Color.surfaceTertiary) : AnyShapeStyle(LinearGradient.brandGradient))
        .cornerRadius(Radius.lg)
        .opacity(isDisabled ? 0.35 : 1.0)
        .disabled(isDisabled || isLoading)
    }
}

#Preview {
    VStack(spacing: 16) {
        GradientButton(label: "Post", icon: "paperplane.fill", action: {})
        GradientButton(label: "Loading", isLoading: true, action: {})
        GradientButton(label: "Disabled", isDisabled: true, action: {})
        GradientButton(label: nil, icon: "paperplane.fill", action: {})
    }
    .padding()
    .background(Color.appBackground)
}
