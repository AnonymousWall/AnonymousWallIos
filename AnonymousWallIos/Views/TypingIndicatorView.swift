//
//  TypingIndicatorView.swift
//  AnonymousWallIos
//

import SwiftUI

struct TypingIndicatorView: View {
    let isTyping: Bool

    @State private var animate = false

    var body: some View {
        HStack(spacing: 8) {
            HStack(spacing: 4) {
                dot(delay: 0.0)
                dot(delay: 0.2)
                dot(delay: 0.4)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.surfaceSecondary)
            .cornerRadius(16)

            Spacer()
        }
        .onAppear {
            guard isTyping else { return }
            animate = true
        }
        .onChange(of: isTyping) { _, typing in
            animate = typing
        }
    }

    private func dot(delay: Double) -> some View {
        Circle()
            .fill(Color.secondary)
            .frame(width: 6, height: 6)
            .offset(y: animate ? -4 : 0)
            .animation(
                Animation.easeInOut(duration: 0.5)
                    .repeatForever(autoreverses: true)
                    .delay(delay),
                value: animate
            )
    }
}
