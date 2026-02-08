//
//  AuthServiceProtocol.swift
//  AnonymousWallIos
//
//  Protocol for authentication service operations
//

import Foundation

protocol AuthServiceProtocol {
    // MARK: - Email Verification Code
    
    /// Send email verification code for registration or login
    /// - Parameters:
    ///   - email: User's email address
    ///   - purpose: "register" or "login"
    func sendEmailVerificationCode(email: String, purpose: String) async throws -> VerificationCodeResponse
    
    // MARK: - Registration
    
    /// Register with email and verification code
    func registerWithEmail(email: String, code: String) async throws -> AuthResponse
    
    // MARK: - Login
    
    /// Login with email and verification code
    func loginWithEmailCode(email: String, code: String) async throws -> AuthResponse
    
    /// Login with email and password
    func loginWithPassword(email: String, password: String) async throws -> AuthResponse
    
    // MARK: - Password Management
    
    /// Set initial password after registration and login
    func setPassword(password: String, token: String, userId: String) async throws
    
    /// Change password when already logged in
    func changePassword(oldPassword: String, newPassword: String, token: String, userId: String) async throws
    
    /// Request password reset (forgot password)
    func requestPasswordReset(email: String) async throws
    
    /// Reset password with verification code
    func resetPassword(email: String, code: String, newPassword: String) async throws -> AuthResponse
    
    // MARK: - Profile Management
    
    /// Update user's profile name
    func updateProfileName(profileName: String, token: String, userId: String) async throws -> User
}
