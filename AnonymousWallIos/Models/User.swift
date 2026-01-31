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
    let createdAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case createdAt = "created_at"
    }
}

struct AuthResponse: Codable {
    let success: Bool
    let message: String
    let user: User?
    let token: String?
}

struct VerificationCodeResponse: Codable {
    let success: Bool
    let message: String
}
