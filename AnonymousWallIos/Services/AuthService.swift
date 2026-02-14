//
//  AuthService.swift
//  AnonymousWallIos
//
//  Authentication service for API calls
//

import Foundation

class AuthService: AuthServiceProtocol {
    static let shared = AuthService()
    
    private let config = AppConfiguration.shared
    private let networkClient = NetworkClient.shared
    
    private init() {}
    
    // MARK: - Email Verification Code
    
    /// Send email verification code for registration or login
    /// - Parameters:
    ///   - email: User's email address
    ///   - purpose: "register" or "login"
    func sendEmailVerificationCode(email: String, purpose: String) async throws -> VerificationCodeResponse {
        let body: [String: String] = [
            "email": email,
            "purpose": purpose
        ]
        
        let request = try APIRequestBuilder()
            .setPath("/auth/email/send-code")
            .setMethod(.POST)
            .setBody(body)
            .build()
        
        return try await networkClient.performRequest(request)
    }
    
    // MARK: - Registration
    
    /// Register with email and verification code
    func registerWithEmail(email: String, code: String) async throws -> AuthResponse {
        let body: [String: String] = [
            "email": email,
            "code": code
        ]
        
        let request = try APIRequestBuilder()
            .setPath("/auth/register/email")
            .setMethod(.POST)
            .setBody(body)
            .build()
        
        return try await networkClient.performRequest(request)
    }
    
    // MARK: - Login
    
    /// Login with email and verification code
    func loginWithEmailCode(email: String, code: String) async throws -> AuthResponse {
        let body: [String: String] = [
            "email": email,
            "code": code
        ]
        
        let request = try APIRequestBuilder()
            .setPath("/auth/login/email")
            .setMethod(.POST)
            .setBody(body)
            .build()
        
        return try await networkClient.performRequest(request)
    }
    
    /// Login with email and password
    func loginWithPassword(email: String, password: String) async throws -> AuthResponse {
        let body: [String: String] = [
            "email": email,
            "password": password
        ]
        
        let request = try APIRequestBuilder()
            .setPath("/auth/login/password")
            .setMethod(.POST)
            .setBody(body)
            .build()
        
        return try await networkClient.performRequest(request)
    }
    
    // MARK: - Password Management
    
    /// Set initial password after registration and login
    func setPassword(password: String, token: String, userId: String) async throws {
        let body: [String: String] = [
            "password": password
        ]
        
        let request = try APIRequestBuilder()
            .setPath("/auth/password/set")
            .setMethod(.POST)
            .setBody(body)
            .setToken(token)
            .setUserId(userId)
            .build()
        
        let _: VerificationCodeResponse = try await networkClient.performRequest(request)
    }
    
    /// Change password when already logged in
    func changePassword(oldPassword: String, newPassword: String, token: String, userId: String) async throws {
        let body: [String: String] = [
            "oldPassword": oldPassword,
            "newPassword": newPassword
        ]
        
        let request = try APIRequestBuilder()
            .setPath("/auth/password/change")
            .setMethod(.POST)
            .setBody(body)
            .setToken(token)
            .setUserId(userId)
            .build()
        
        let _: VerificationCodeResponse = try await networkClient.performRequest(request)
    }
    
    /// Request password reset (forgot password)
    func requestPasswordReset(email: String) async throws {
        let body: [String: String] = [
            "email": email
        ]
        
        let request = try APIRequestBuilder()
            .setPath("/auth/password/reset-request")
            .setMethod(.POST)
            .setBody(body)
            .build()
        
        let _: VerificationCodeResponse = try await networkClient.performRequest(request)
    }
    
    /// Reset password with verification code
    func resetPassword(email: String, code: String, newPassword: String) async throws -> AuthResponse {
        let body: [String: String] = [
            "email": email,
            "code": code,
            "newPassword": newPassword
        ]
        
        let request = try APIRequestBuilder()
            .setPath("/auth/password/reset")
            .setMethod(.POST)
            .setBody(body)
            .build()
        
        return try await networkClient.performRequest(request)
    }
}
