//
//  NotificationInboxView.swift
//  AnonymousWallIos
//
//  TikTok-style notification inbox listing all received notifications
//

import SwiftUI

struct NotificationInboxView: View {
    @EnvironmentObject var authState: AuthState
    @StateObject private var viewModel: NotificationInboxViewModel
    @ObservedObject var coordinator: NotificationCoordinator

    init(coordinator: NotificationCoordinator, service: NotificationInboxServiceProtocol = NotificationInboxService.shared) {
        self.coordinator = coordinator
        _viewModel = StateObject(wrappedValue: NotificationInboxViewModel(service: service))
    }

    var body: some View {
        NavigationStack(path: $coordinator.path) {
            content
                .navigationTitle("Notifications")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar { toolbarContent }
                .navigationDestination(for: NotificationCoordinator.Destination.self) { destination in
                    notificationDestinationView(for: destination)
                }
        }
        .background(Color.appBackground.ignoresSafeArea())
        .onAppear {
            viewModel.loadNotifications(authState: authState)
            viewModel.loadUnreadCount(authState: authState)
        }
        .onDisappear {
            viewModel.cleanup()
        }
        .onChange(of: viewModel.unreadCount) { _, newCount in
            coordinator.tabCoordinator?.notificationUnreadCount = newCount
        }
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading && viewModel.notifications.isEmpty {
            loadingView
        } else if viewModel.notifications.isEmpty && !viewModel.isLoading {
            emptyView
        } else {
            notificationList
        }
    }

    private var loadingView: some View {
        VStack {
            Spacer()
            ProgressView("Loading notifications...")
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var emptyView: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "bell.slash")
                .font(.system(size: 60))
                .foregroundStyle(LinearGradient.brandGradient)
                .accessibilityHidden(true)
            VStack(spacing: 8) {
                Text("No notifications yet")
                    .font(.title3.bold())
                    .foregroundColor(.textPrimary)
                Text("You'll be notified when someone comments on your posts.")
                    .font(.body)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("No notifications yet. You'll be notified when someone comments on your posts.")
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var notificationList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(viewModel.notifications) { notification in
                    NotificationRowView(notification: notification) {
                        viewModel.markRead(notification, authState: authState)
                        navigateToContent(for: notification)
                    }
                    .onAppear {
                        viewModel.loadMoreIfNeeded(for: notification, authState: authState)
                    }

                    Divider()
                        .padding(.leading, 60)
                }

                if viewModel.isLoadingMore {
                    HStack {
                        Spacer()
                        ProgressView().padding()
                        Spacer()
                    }
                }
            }

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.accentRed)
                    .font(.caption)
                    .padding()
            }
        }
        .refreshable {
            await viewModel.refresh(authState: authState)
        }
        .tint(.accentPurple)
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        if !viewModel.notifications.isEmpty {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Mark All Read") {
                    viewModel.markAllRead(authState: authState)
                }
                .font(.caption.weight(.semibold))
                .foregroundColor(.accentPurple)
                .accessibilityLabel("Mark all notifications as read")
            }
        }
    }

    // MARK: - Navigation

    private func navigateToContent(for notification: AppNotification) {
        switch notification.type {
        case "COMMENT":
            coordinator.navigate(to: .postDetailById(notification.entityId.uuidString))
        case "INTERNSHIP_COMMENT":
            coordinator.navigate(to: .internshipDetailById(notification.entityId.uuidString))
        case "MARKETPLACE_COMMENT":
            coordinator.navigate(to: .marketplaceDetailById(notification.entityId.uuidString))
        default:
            break
        }
    }

    @ViewBuilder
    private func notificationDestinationView(for destination: NotificationCoordinator.Destination) -> some View {
        switch destination {
        case .postDetailById(let postId):
            PostDetailByIdView(postId: postId) { userId, userName in
                coordinator.navigateToChatWithUser(userId: userId, userName: userName)
            }
        case .internshipDetailById(let internshipId):
            NotificationInternshipDetailByIdView(internshipId: internshipId) { userId, userName in
                coordinator.navigateToChatWithUser(userId: userId, userName: userName)
            }
        case .marketplaceDetailById(let itemId):
            NotificationMarketplaceDetailByIdView(itemId: itemId) { userId, userName in
                coordinator.navigateToChatWithUser(userId: userId, userName: userName)
            }
        }
    }
}

// MARK: - NotificationRowView

private struct NotificationRowView: View {
    let notification: AppNotification
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 12) {
                // Unread indicator dot
                Circle()
                    .fill(notification.read ? Color.clear : Color.accentPurple)
                    .frame(width: 8, height: 8)
                    .padding(.top, 6)
                    .accessibilityHidden(true)

                // Icon
                Image(systemName: notificationIcon)
                    .font(.system(size: 20))
                    .foregroundColor(notificationColor)
                    .frame(width: 32, height: 32)
                    .accessibilityHidden(true)

                // Text content
                VStack(alignment: .leading, spacing: 4) {
                    Text(notificationText)
                        .font(.bodyMedium)
                        .foregroundColor(.textPrimary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)

                    if let title = notification.entityTitle, !title.isEmpty {
                        Text(title)
                            .font(.bodySmall)
                            .foregroundColor(.textSecondary)
                            .lineLimit(1)
                    }

                    Text(DateFormatting.formatDateTime(notification.createdAt))
                        .font(.captionFont)
                        .foregroundColor(.textTertiary)
                }

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(notification.read ? Color.clear : Color.accentPurple.opacity(0.05))
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint("Double tap to view \(notificationTypeName)")
    }

    // MARK: - Helpers

    private var notificationText: String {
        let actor = notification.actorProfileName ?? "Someone"
        switch notification.type {
        case "COMMENT":
            return "\(actor) commented on your post"
        case "INTERNSHIP_COMMENT":
            return "\(actor) commented on your internship posting"
        case "MARKETPLACE_COMMENT":
            return "\(actor) commented on your marketplace listing"
        default:
            return "\(actor) commented"
        }
    }

    private var notificationIcon: String {
        switch notification.type {
        case "INTERNSHIP_COMMENT": return "briefcase"
        case "MARKETPLACE_COMMENT": return "cart"
        default: return "bubble.left"
        }
    }

    private var notificationColor: Color {
        switch notification.type {
        case "INTERNSHIP_COMMENT": return .accentBlue
        case "MARKETPLACE_COMMENT": return .accentGreen
        default: return .accentPurple
        }
    }

    private var notificationTypeName: String {
        switch notification.type {
        case "INTERNSHIP_COMMENT": return "internship"
        case "MARKETPLACE_COMMENT": return "marketplace listing"
        default: return "post"
        }
    }

    private var accessibilityLabel: String {
        var label = notificationText
        if let title = notification.entityTitle, !title.isEmpty {
            label += ": \(title)"
        }
        if !notification.read {
            label = "Unread — " + label
        }
        return label
    }
}

// MARK: - By-ID Wrapper Views

/// Wrapper for navigating to a marketplace item using only its ID.
/// Fetches the full item from the service before displaying MarketplaceDetailView.
private struct NotificationMarketplaceDetailByIdView: View {
    let itemId: String
    let onTapAuthor: (String, String) -> Void
    @EnvironmentObject var authState: AuthState
    @State private var item: MarketplaceItem?
    @State private var loadFailed = false

    var body: some View {
        Group {
            if let binding = Binding($item) {
                MarketplaceDetailView(item: binding, onTapAuthor: onTapAuthor)
            } else if loadFailed {
                Text("Failed to load marketplace item.")
                    .foregroundColor(.textSecondary)
                    .padding()
            } else {
                ProgressView()
            }
        }
        .task { await loadItem() }
    }

    private func loadItem() async {
        guard let token = authState.authToken,
              let userId = authState.currentUser?.id else { return }
        do {
            item = try await MarketplaceService.shared.getItem(
                itemId: itemId,
                token: token,
                userId: userId
            )
        } catch {
            loadFailed = true
        }
    }
}

/// Wrapper for navigating to an internship using only its ID.
/// Fetches the full internship from the service before displaying InternshipDetailView.
private struct NotificationInternshipDetailByIdView: View {
    let internshipId: String
    let onTapAuthor: (String, String) -> Void
    @EnvironmentObject var authState: AuthState
    @State private var internship: Internship?
    @State private var loadFailed = false

    var body: some View {
        Group {
            if let binding = Binding($internship) {
                InternshipDetailView(internship: binding, onTapAuthor: onTapAuthor)
            } else if loadFailed {
                Text("Failed to load internship.")
                    .foregroundColor(.textSecondary)
                    .padding()
            } else {
                ProgressView()
            }
        }
        .task { await loadInternship() }
    }

    private func loadInternship() async {
        guard let token = authState.authToken,
              let userId = authState.currentUser?.id else { return }
        do {
            internship = try await InternshipService.shared.getInternship(
                internshipId: internshipId,
                token: token,
                userId: userId
            )
        } catch {
            loadFailed = true
        }
    }
}

#Preview {
    NotificationInboxView(coordinator: NotificationCoordinator())
        .environmentObject(AuthState())
        .environmentObject(BlockViewModel())
}
