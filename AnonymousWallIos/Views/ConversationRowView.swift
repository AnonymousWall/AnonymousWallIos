//
//  ConversationRowView.swift
//  AnonymousWallIos
//

import SwiftUI

struct ConversationRowView: View {
    let conversation: Conversation
    var isLoading: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            // Avatar placeholder
            Circle()
                .fill(LinearGradient.brandGradient)
                .frame(width: 50, height: 50)
                .overlay(
                    Text(conversation.profileName.prefix(1))
                        .font(.title3.bold())
                        .foregroundColor(.white)
                )

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(conversation.profileName)
                        .font(.headline)
                        .foregroundColor(.textPrimary)

                    Spacer()

                    if let lastMessage = conversation.lastMessage {
                        Text(DateFormatting.formatRelativeTime(lastMessage.createdAt))
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                    }
                }

                HStack {
                    if let lastMessage = conversation.lastMessage {
                        Text(lastMessagePreview(lastMessage))
                            .font(.subheadline)
                            .foregroundColor(.textSecondary)
                            .lineLimit(1)
                    } else {
                        Text("No messages")
                            .font(.subheadline)
                            .foregroundColor(.textSecondary)
                            .italic()
                    }

                    Spacer()

                    if conversation.unreadCount > 0 {
                        BadgeView(count: conversation.unreadCount)
                    }
                }
            }
        }
        .padding(.vertical, 4)
        .skeletonLoading(isLoading)
    }

    private func lastMessagePreview(_ message: Message) -> String {
        if let imageUrl = message.imageUrl, !imageUrl.isEmpty, message.content.isEmpty {
            return "📷 Photo"
        }
        return message.content
    }
}
