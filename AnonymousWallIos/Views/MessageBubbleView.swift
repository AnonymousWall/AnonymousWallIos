//
//  MessageBubbleView.swift
//  AnonymousWallIos
//

import SwiftUI

struct MessageBubbleView: View {
    let message: Message
    let isCurrentUser: Bool
    var onTapImage: ((String) -> Void)?

    var body: some View {
        HStack {
            if isCurrentUser { Spacer() }

            VStack(alignment: isCurrentUser ? .trailing : .leading, spacing: 4) {
                // Image bubble
                if let imageUrl = message.imageUrl {
                    AuthenticatedImageView(objectName: imageUrl, contentMode: .fill)
                        .frame(width: 200, height: 200)
                        .clipped()
                        .cornerRadius(12)
                        .onTapGesture { onTapImage?(imageUrl) }
                        .accessibilityLabel("Image message")
                        .accessibilityHint("Double tap to view full screen")
                }

                // Text bubble (only if non-empty)
                if !message.content.isEmpty {
                    Text(message.content)
                        .font(.body)
                        .foregroundColor(isCurrentUser ? .white : .textPrimary)
                        .padding(12)
                        .background(isCurrentUser ? AnyShapeStyle(LinearGradient.brandGradient) : AnyShapeStyle(Color.surfaceSecondary))
                        .cornerRadius(16)
                        .accessibilityLabel("Message: \(message.content)")
                }

                // Timestamp + status
                HStack(spacing: 4) {
                    Text(DateFormatting.formatRelativeTime(message.createdAt))
                        .font(.caption2)
                        .foregroundColor(.textSecondary)

                    if isCurrentUser {
                        statusIcon
                    }
                }
            }
            .frame(maxWidth: 280, alignment: isCurrentUser ? .trailing : .leading)

            if !isCurrentUser { Spacer() }
        }
    }

    private var statusIcon: some View {
        Group {
            switch message.localStatus {
            case .sending:
                Image(systemName: "clock")
                    .font(.caption2)
                    .foregroundColor(.textSecondary)
            case .sent, .delivered:
                Image(systemName: "checkmark")
                    .font(.caption2)
                    .foregroundColor(.textSecondary)
            case .read:
                Image(systemName: "checkmark.circle.fill")
                    .font(.caption2)
                    .foregroundColor(.blue)
            case .failed:
                Image(systemName: "exclamationmark.circle")
                    .font(.caption2)
                    .foregroundColor(.accentRed)
            }
        }
    }
}
