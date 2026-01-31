//
//  User.swift
//  AnonymousWallIos
//
//  Authentication user model
//

import Foundation

struct User: Codable, Identifiable {
    let id: String
    let email: String
    let isVerified: Bool
    let createdAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case isVerified
        case createdAt
    }
}

struct AuthResponse: Codable {
    let accessToken: String
    let user: User
}

struct VerificationCodeResponse: Codable {
    let message: String?
    let success: Bool?
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        // Try to decode as a simple message string first
        if let message = try? container.decode(String.self) {
            self.message = message
            self.success = true
        } else {
            // Otherwise decode as an object
            let objContainer = try decoder.container(keyedBy: CodingKeys.self)
            self.message = try? objContainer.decode(String.self, forKey: .message)
            self.success = try? objContainer.decode(Bool.self, forKey: .success)
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case message
        case success
    }
}

struct ErrorResponse: Codable {
    let error: String?
    let message: String?
}
