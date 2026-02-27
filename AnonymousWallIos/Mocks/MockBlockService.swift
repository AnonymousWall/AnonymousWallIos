//
//  MockBlockService.swift
//  AnonymousWallIos
//
//  Mock implementation of BlockServiceProtocol for unit testing
//

import Foundation

class MockBlockService: BlockServiceProtocol {

    // MARK: - Configuration

    enum MockBehavior {
        case success
        case failure(Error)
        case emptyState
    }

    enum MockError: Error, LocalizedError {
        case unauthorized
        case networkError
        case serverError
        case userNotFound

        var errorDescription: String? {
            switch self {
            case .unauthorized: return "Unauthorized access"
            case .networkError: return "Network error"
            case .serverError: return "Server error"
            case .userNotFound: return "User not found"
            }
        }
    }

    // MARK: - State Tracking

    var blockUserCalled = false
    var unblockUserCalled = false
    var getBlockListCalled = false

    // MARK: - Configurable Behavior

    var blockUserBehavior: MockBehavior = .success
    var unblockUserBehavior: MockBehavior = .success
    var getBlockListBehavior: MockBehavior = .success

    // MARK: - Configurable State

    var mockBlockedUsers: [BlockedUser] = []

    // MARK: - BlockServiceProtocol

    func blockUser(targetUserId: String, token: String, userId: String) async throws {
        blockUserCalled = true

        switch blockUserBehavior {
        case .success:
            return
        case .failure(let error):
            throw error
        case .emptyState:
            throw MockError.serverError
        }
    }

    func unblockUser(targetUserId: String, token: String, userId: String) async throws {
        unblockUserCalled = true

        switch unblockUserBehavior {
        case .success:
            return
        case .failure(let error):
            throw error
        case .emptyState:
            throw MockError.serverError
        }
    }

    func getBlockList(token: String, userId: String) async throws -> [BlockedUser] {
        getBlockListCalled = true

        switch getBlockListBehavior {
        case .success:
            return mockBlockedUsers
        case .failure(let error):
            throw error
        case .emptyState:
            return []
        }
    }
}
