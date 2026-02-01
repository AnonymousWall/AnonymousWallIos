//
//  AuthService.swift
//  AnonymousWallIos
//
//  Authentication service for API calls
//

import Foundation

class AuthService {
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
        guard let url = URL(string: "\(config.fullAPIBaseURL)/auth/email/send-code") else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: String] = [
            "email": email,
            "purpose": purpose
        ]
        request.httpBody = try JSONEncoder().encode(body)
        
        return try await networkClient.performRequest(request)
    }
    
    // MARK: - Registration
    
    /// Register with email and verification code
    func registerWithEmail(email: String, code: String) async throws -> AuthResponse {
        guard let url = URL(string: "\(config.fullAPIBaseURL)/auth/register/email") else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: String] = [
            "email": email,
            "code": code
        ]
        request.httpBody = try JSONEncoder().encode(body)
        
        return try await networkClient.performRequest(request)
    }
    
    // MARK: - Login
    
    /// Login with email and verification code
    func loginWithEmailCode(email: String, code: String) async throws -> AuthResponse {
        guard let url = URL(string: "\(config.fullAPIBaseURL)/auth/login/email") else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: String] = [
            "email": email,
            "code": code
        ]
        request.httpBody = try JSONEncoder().encode(body)
        
        return try await networkClient.performRequest(request)
    }
    
    /// Login with email and password
    func loginWithPassword(email: String, password: String) async throws -> AuthResponse {
        guard let url = URL(string: "\(config.fullAPIBaseURL)/auth/login/password") else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: String] = [
            "email": email,
            "password": password
        ]
        request.httpBody = try JSONEncoder().encode(body)
        
        return try await networkClient.performRequest(request)
    }
    
    // MARK: - Password Management
    
    /// Set initial password after registration and login
    func setPassword(password: String, token: String, userId: String) async throws {
        guard let url = URL(string: "\(config.fullAPIBaseURL)/auth/password/set") else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(userId, forHTTPHeaderField: "X-User-Id")
        
        let body: [String: String] = [
            "password": password
        ]
        request.httpBody = try JSONEncoder().encode(body)
        
        let _: VerificationCodeResponse = try await networkClient.performRequest(request)
    }
    
    /// Change password when already logged in
    func changePassword(oldPassword: String, newPassword: String, token: String, userId: String) async throws {
        guard let url = URL(string: "\(config.fullAPIBaseURL)/auth/password/change") else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(userId, forHTTPHeaderField: "X-User-Id")
        
        let body: [String: String] = [
            "oldPassword": oldPassword,
            "newPassword": newPassword
        ]
        request.httpBody = try JSONEncoder().encode(body)
        
        let _: VerificationCodeResponse = try await networkClient.performRequest(request)
    }
    
    /// Request password reset (forgot password)
    func requestPasswordReset(email: String) async throws {
        guard let url = URL(string: "\(config.fullAPIBaseURL)/auth/password/reset-request") else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: String] = [
            "email": email
        ]
        request.httpBody = try JSONEncoder().encode(body)
        
        let _: VerificationCodeResponse = try await networkClient.performRequest(request)
    }
    
    /// Reset password with verification code
    func resetPassword(email: String, code: String, newPassword: String) async throws -> AuthResponse {
        guard let url = URL(string: "\(config.fullAPIBaseURL)/auth/password/reset") else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: String] = [
            "email": email,
            "code": code,
            "newPassword": newPassword
        ]
        request.httpBody = try JSONEncoder().encode(body)
        
        return try await networkClient.performRequest(request)
    }
}
