//
//  BlockService.swift
//  AnonymousWallIos
//
//  Service for block/unblock user API calls
//

import Foundation

class BlockService: BlockServiceProtocol {
    static let shared: BlockServiceProtocol = BlockService()

    private let networkClient = NetworkClient.shared

    private init() {}

    func blockUser(targetUserId: String, token: String, userId: String) async throws {
        let request = try APIRequestBuilder()
            .setPath("/users/me/blocks/\(targetUserId)")
            .setMethod(.POST)
            .setToken(token)
            .setUserId(userId)
            .build()

        try await networkClient.performRequestWithoutResponse(request)
    }

    func unblockUser(targetUserId: String, token: String, userId: String) async throws {
        let request = try APIRequestBuilder()
            .setPath("/users/me/blocks/\(targetUserId)")
            .setMethod(.DELETE)
            .setToken(token)
            .setUserId(userId)
            .build()

        try await networkClient.performRequestWithoutResponse(request)
    }

    func getBlockList(token: String, userId: String) async throws -> [BlockedUser] {
        let request = try APIRequestBuilder()
            .setPath("/users/me/blocks")
            .setMethod(.GET)
            .setToken(token)
            .setUserId(userId)
            .build()

        let response: BlockListResponse = try await networkClient.performRequest(request)
        return response.data
    }
}
