//
//  MessageHistoryResponse.swift
//  AnonymousWallIos
//
//  Created by Ziyi Huang on 3/11/26.
//

import Foundation

struct MessageHistoryResponse: Codable {
    let messages: [Message]
    let pagination: PaginationInfo
}

/// API response DTO — distinct from Pagination (which tracks mutable UI state)
struct PaginationInfo: Codable {
    let page: Int
    let limit: Int
    let total: Int
    let totalPages: Int
}
