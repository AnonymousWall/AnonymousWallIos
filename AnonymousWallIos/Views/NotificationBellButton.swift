//
//  NotificationBellButton.swift
//  AnonymousWallIos
//

import SwiftUI

/// Reusable bell icon button with unread badge, used in feed view toolbars.
struct NotificationBellButton: View {
    @ObservedObject var notificationsViewModel: NotificationsViewModel
    @Binding var showNotifications: Bool

    var body: some View {
        Button {
            showNotifications = true
        } label: {
            ZStack(alignment: .topTrailing) {
                Image(systemName: "bell.fill")
                    .font(.title3)
                    .foregroundColor(.textPrimary)

                if notificationsViewModel.unreadCount > 0 {
                    ZStack {
                        Circle()
                            .fill(Color.accentRed)
                            .frame(width: 16, height: 16)
                        Text(notificationsViewModel.unreadCount > 9 ? "9+" : "\(notificationsViewModel.unreadCount)")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .offset(x: 8, y: -8)
                }
            }
        }
        .accessibilityLabel("Notifications")
        .accessibilityValue(notificationsViewModel.unreadCount > 0
            ? "\(notificationsViewModel.unreadCount) unread" : "No unread notifications")
    }
}
