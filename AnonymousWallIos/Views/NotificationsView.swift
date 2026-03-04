//
//  NotificationsView.swift
//  AnonymousWallIos
//

import SwiftUI

struct NotificationsView: View {
    @EnvironmentObject var authState: AuthState
    @ObservedObject var viewModel: NotificationsViewModel
    @Environment(\.dismiss) var dismiss

    /// Called when user taps a COMMENT notification. Wall not available — always routes to national/home.
    var onNavigateToPost: ((_ postId: String) -> Void)?
    /// Called when user taps an INTERNSHIP_COMMENT notification
    var onNavigateToInternship: ((_ internshipId: String) -> Void)?
    /// Called when user taps a MARKETPLACE_COMMENT notification
    var onNavigateToMarketplace: ((_ itemId: String) -> Void)?

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.notifications.isEmpty {
                    ProgressView("Loading...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.appBackground)
                } else if viewModel.notifications.isEmpty && !viewModel.isLoading {
                    emptyStateView
                } else {
                    notificationsList
                }
            }
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { dismiss() }
                        .foregroundColor(.accentPurple)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if viewModel.unreadCount > 0 {
                        Button("Mark all read") {
                            Task { await viewModel.markAllRead(authState: authState) }
                        }
                        .font(.caption)
                        .foregroundColor(.accentPurple)
                    }
                }
            }
        }
        .background(Color.appBackground.ignoresSafeArea())
        .task {
            await viewModel.loadNotifications(authState: authState)
        }
        .refreshable {
            await viewModel.refresh(authState: authState)
        }
    }

    // MARK: - Subviews

    private var notificationsList: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(viewModel.notifications) { notification in
                    Button {
                        handleTap(notification)
                    } label: {
                        NotificationRowView(notification: notification)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .onAppear {
                        if notification.id == viewModel.notifications.last?.id {
                            Task { await viewModel.loadMore(authState: authState) }
                        }
                    }
                }

                if viewModel.isLoadingMore {
                    ProgressView().padding()
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)
        }
        .background(Color.appBackground)
    }

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
            ZStack {
                Circle()
                    .fill(LinearGradient.brandGradient)
                    .frame(width: 100, height: 100)
                    .blur(radius: 30)
                Image(systemName: "bell.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(LinearGradient.brandGradient)
            }
            VStack(spacing: 8) {
                Text("No notifications yet")
                    .font(.title3.bold())
                    .foregroundColor(.textPrimary)
                Text("When someone interacts with your posts, you'll see it here.")
                    .font(.body)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            Spacer()
        }
        .background(Color.appBackground)
    }

    // MARK: - Navigation

    /// Delay (nanoseconds) to let the sheet dismiss animation complete before pushing navigation.
    private let sheetDismissalDelay: UInt64 = 300_000_000

    private func handleTap(_ notification: AppNotification) {
        Task { await viewModel.markRead(notification, authState: authState) }
        viewModel.pendingNavigation = notification
        dismiss()
    }
}
