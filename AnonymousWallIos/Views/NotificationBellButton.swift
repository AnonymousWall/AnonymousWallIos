//
//  NotificationBellButton.swift
//  AnonymousWallIos
//
//  Reusable toolbar bell button showing unread notification count badge.
//

import SwiftUI

struct NotificationBellButton: View {
    @ObservedObject var viewModel: NotificationsViewModel
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .topTrailing) {
                Image(systemName: "bell.fill")
                    .font(.title3)
                    .foregroundColor(.textPrimary)

                if viewModel.unreadCount > 0 {
                    ZStack {
                        Circle()
                            .fill(Color.accentRed)
                            .frame(width: 16, height: 16)
                        Text(viewModel.badgeText)
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .offset(x: 8, y: -8)
                }
            }
        }
        .accessibilityLabel("Notifications")
        .accessibilityValue(viewModel.unreadCount > 0 ? "\(viewModel.unreadCount) unread" : "No unread notifications")
    }
}
