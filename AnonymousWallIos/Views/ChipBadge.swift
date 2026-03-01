//
//  ChipBadge.swift
//  AnonymousWallIos
//
//  Pill-shaped badge for type indicators, tags, and status labels.
//

import SwiftUI

struct ChipBadge: View {
    let label: String
    var icon: String? = nil
    let color: Color

    var body: some View {
        HStack(spacing: Spacing.xs) {
            if let icon {
                Image(systemName: icon)
                    .font(.captionFont)
                    .accessibilityHidden(true)
            }
            Text(label)
                .font(.labelSmall)
        }
        .foregroundColor(color)
        .padding(.vertical, 6)
        .padding(.horizontal, Spacing.md)
        .background(color.opacity(0.12))
        .overlay(
            Capsule()
                .stroke(color.opacity(0.25), lineWidth: 1)
        )
        .clipShape(Capsule())
    }
}

#Preview {
    HStack(spacing: 12) {
        ChipBadge(label: "Campus", icon: "building.2", color: .accentPurple)
        ChipBadge(label: "National", color: .accentBlue)
        ChipBadge(label: "Like New", color: .accentGreen)
    }
    .padding()
    .background(Color.appBackground)
}
