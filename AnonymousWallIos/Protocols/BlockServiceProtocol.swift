//
//  BlockServiceProtocol.swift
//  AnonymousWallIos
//
//  Protocol for block/unblock user service
//

import Foundation

protocol BlockServiceProtocol {
    func blockUser(targetUserId: String, token: String, userId: String) async throws
    func unblockUser(targetUserId: String, token: String, userId: String) async throws
    func getBlockList(token: String, userId: String) async throws -> [BlockedUser]
}
