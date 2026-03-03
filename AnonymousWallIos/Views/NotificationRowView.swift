//
//  NotificationRowView.swift
//  AnonymousWallIos
//

import SwiftUI

struct NotificationRowView: View {
    let notification: AppNotification

    var iconName: String {
        switch notification.type {
        case .comment:            return "bubble.left.fill"
        case .internshipComment:  return "briefcase.fill"
        case .marketplaceComment: return "tag.fill"
        case .unknown:            return "bell.fill"
        }
    }

    var actionText: String {
        switch notification.type {
        case .comment:            return "commented on your post"
        case .internshipComment:  return "commented on your internship"
        case .marketplaceComment: return "commented on your listing"
        case .unknown:            return "did something"
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(Color.accentPurple)
                .frame(width: 8, height: 8)
                .padding(.top, 6)
                .opacity(notification.read ? 0 : 1)

            IconBadge(systemName: iconName, color: .accentPurple)

            VStack(alignment: .leading, spacing: 4) {
                Text("\(notification.actorProfileName ?? "Someone") \(actionText)")
                    .font(.bodyMedium)
                    .foregroundColor(.textPrimary)

                if let title = notification.entityTitle, !title.isEmpty {
                    Text(title)
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                        .lineLimit(1)
                }

                Text(DateFormatting.formatRelativeTime(notification.createdAt))
                    .font(.caption2)
                    .foregroundColor(.textSecondary)
            }

            Spacer()
        }
        .padding()
        .background(
            notification.read
                ? Color.surfacePrimary
                : Color.accentPurple.opacity(0.05)
        )
        .cornerRadius(Radius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: Radius.lg)
                .stroke(Color.borderSubtle, lineWidth: 1)
        )
    }
}
