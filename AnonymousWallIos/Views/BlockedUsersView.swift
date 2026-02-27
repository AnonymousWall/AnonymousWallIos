//
//  BlockedUsersView.swift
//  AnonymousWallIos
//
//  View showing the current user's block list with unblock capability
//

import SwiftUI

struct BlockedUsersView: View {
    @EnvironmentObject var authState: AuthState
    @EnvironmentObject var blockViewModel: BlockViewModel
    @State private var showUnblockConfirmation = false
    @State private var userToUnblock: BlockedUser?
    @State private var showSuccessAlert = false
    @State private var successMessage = ""

    var body: some View {
        Group {
            if blockViewModel.isLoading {
                ProgressView("Loading blocked users...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .accessibilityLabel("Loading blocked users")
            } else if blockViewModel.blockedUsers.isEmpty {
                emptyStateView
            } else {
                List {
                    ForEach(blockViewModel.blockedUsers) { user in
                        BlockedUserRow(user: user) {
                            userToUnblock = user
                            HapticFeedback.warning()
                            showUnblockConfirmation = true
                        }
                    }
                }
                .refreshable {
                    blockViewModel.loadBlockList(authState: authState)
                }
            }
        }
        .navigationTitle("Blocked Users")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            blockViewModel.loadBlockList(authState: authState)
        }
        .confirmationDialog(
            "Unblock User",
            isPresented: $showUnblockConfirmation,
            titleVisibility: .visible
        ) {
            Button("Unblock") {
                if let user = userToUnblock {
                    blockViewModel.unblockUser(targetUserId: user.blockedUserId, authState: authState) {
                        successMessage = "User unblocked successfully"
                        showSuccessAlert = true
                    }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This user will be able to see your content again.")
        }
        .alert("Error", isPresented: .init(
            get: { blockViewModel.errorMessage != nil },
            set: { if !$0 { blockViewModel.errorMessage = nil } }
        )) {
            Button("Retry") { blockViewModel.loadBlockList(authState: authState) }
            Button("Cancel", role: .cancel) { blockViewModel.errorMessage = nil }
        } message: {
            if let error = blockViewModel.errorMessage {
                Text(error)
            }
        }
        .alert("Success", isPresented: $showSuccessAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(successMessage)
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.fill.checkmark")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
                .accessibilityHidden(true)
            Text("No Blocked Users")
                .font(.headline)
                .foregroundColor(.secondary)
            Text("Users you block will appear here.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("No blocked users. Users you block will appear here.")
    }
}

// MARK: - Blocked User Row

private struct BlockedUserRow: View {
    let user: BlockedUser
    let onUnblock: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(user.blockedUserId)
                    .font(.body)
                    .accessibilityLabel("Blocked user ID: \(user.blockedUserId)")
                Text("Blocked \(DateFormatting.formatRelativeTime(user.createdAt))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .accessibilityLabel("Blocked \(DateFormatting.formatRelativeTime(user.createdAt))")
            }

            Spacer()

            Button(action: onUnblock) {
                Text("Unblock")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.red)
            }
            .buttonStyle(.bordered)
            .tint(.red)
            .accessibilityLabel("Unblock user \(user.blockedUserId)")
            .accessibilityHint("Double tap to unblock this user")
        }
        .padding(.vertical, 4)
    }
}
