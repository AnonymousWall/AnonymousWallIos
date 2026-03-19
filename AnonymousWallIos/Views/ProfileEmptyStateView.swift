//
//  ProfileEmptyStateView.swift
//  AnonymousWallIos
//
//  Reusable empty state used across the profile content segments.
//

import SwiftUI

private let emptyStateIconSize: CGFloat = 60
private let emptyStateGlowSize: CGFloat = 100
private let emptyStateMinHeight: CGFloat = 300

struct ProfileEmptyStateView: View {
    let gradient: LinearGradient
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: Spacing.xl) {
            ZStack {
                Circle()
                    .fill(gradient)
                    .frame(width: emptyStateGlowSize, height: emptyStateGlowSize)
                    .blur(radius: 30)

                Image(systemName: icon)
                    .font(.system(size: emptyStateIconSize))
                    .foregroundStyle(gradient)
                    .accessibilityHidden(true)
            }

            VStack(spacing: Spacing.sm) {
                Text(title)
                    .font(.title3.bold())
                    .foregroundColor(.textPrimary)
                Text(subtitle)
                    .font(.body)
                    .foregroundColor(.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, minHeight: emptyStateMinHeight)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(subtitle)")
    }
}
