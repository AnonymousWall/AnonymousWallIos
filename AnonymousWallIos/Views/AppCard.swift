//
//  AppCard.swift
//  AnonymousWallIos
//
//  Standard card container used throughout the app.
//

import SwiftUI

struct AppCard<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            content()
        }
        .padding(Spacing.lg)
        .background(Color.surfacePrimary)
        .cornerRadius(Radius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: Radius.lg)
                .stroke(Color.borderSubtle, lineWidth: 1)
        )
    }
}

#Preview {
    AppCard {
        Text("Card content")
            .foregroundColor(.textPrimary)
    }
    .padding()
    .background(Color.appBackground)
}
