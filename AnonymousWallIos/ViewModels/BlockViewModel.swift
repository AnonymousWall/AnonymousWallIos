//
//  BlockViewModel.swift
//  AnonymousWallIos
//
//  ViewModel for managing block/unblock user operations
//

import Foundation
import Combine

@MainActor
class BlockViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var blockedUsers: [BlockedUser] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    // MARK: - Publishers

    /// Emits the blocked userId immediately after a successful block, enabling reactive feed filtering.
    var userBlockedPublisher: AnyPublisher<String, Never> {
        userBlockedSubject.eraseToAnyPublisher()
    }

    // MARK: - Private Properties

    private let blockService: BlockServiceProtocol
    private var loadTask: Task<Void, Never>?
    private let userBlockedSubject = PassthroughSubject<String, Never>()

    // MARK: - Initialization

    init(blockService: BlockServiceProtocol = BlockService.shared) {
        self.blockService = blockService
    }

    deinit {
        loadTask?.cancel()
    }

    // MARK: - Public Methods

    func loadBlockList(authState: AuthState) {
        guard let token = authState.authToken,
              let userId = authState.currentUser?.id else {
            errorMessage = "Authentication required"
            return
        }

        loadTask?.cancel()
        loadTask = Task { [weak self] in
            guard let self else { return }
            isLoading = true
            errorMessage = nil

            do {
                let users = try await blockService.getBlockList(token: token, userId: userId)
                guard !Task.isCancelled else { return }
                blockedUsers = users
            } catch {
                guard !Task.isCancelled else { return }
                errorMessage = "Failed to load blocked users. Please try again."
            }

            isLoading = false
        }
    }

    func blockUser(targetUserId: String, authState: AuthState, onSuccess: @escaping () -> Void) {
        guard let token = authState.authToken,
              let userId = authState.currentUser?.id else {
            errorMessage = "Authentication required"
            return
        }

        Task { [weak self] in
            guard let self else { return }

            do {
                try await blockService.blockUser(targetUserId: targetUserId, token: token, userId: userId)
                guard !Task.isCancelled else { return }
                userBlockedSubject.send(targetUserId)
                HapticFeedback.success()
                onSuccess()
            } catch {
                guard !Task.isCancelled else { return }
                HapticFeedback.error()
                errorMessage = "Failed to block user. Please try again."
            }
        }
    }

    func unblockUser(targetUserId: String, authState: AuthState, onSuccess: @escaping () -> Void) {
        guard let token = authState.authToken,
              let userId = authState.currentUser?.id else {
            errorMessage = "Authentication required"
            return
        }

        Task { [weak self] in
            guard let self else { return }

            do {
                try await blockService.unblockUser(targetUserId: targetUserId, token: token, userId: userId)
                guard !Task.isCancelled else { return }
                blockedUsers.removeAll { $0.blockedUserId == targetUserId }
                HapticFeedback.success()
                onSuccess()
            } catch {
                guard !Task.isCancelled else { return }
                HapticFeedback.error()
                errorMessage = "Failed to unblock user. Please try again."
            }
        }
    }
}
