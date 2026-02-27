//
//  BlockModels.swift
//  AnonymousWallIos
//
//  Models for block/unblock user feature
//

import Foundation

struct BlockedUser: Codable, Identifiable {
    let blockedUserId: String
    let createdAt: String
    var id: String { blockedUserId }
}

struct BlockListResponse: Codable {
    let data: [BlockedUser]
}

struct BlockResponse: Codable {
    let message: String
}
