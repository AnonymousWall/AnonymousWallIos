//
//  AuthService.swift
//  AnonymousWallIos
//
//  Authentication service for API calls
//

import Foundation

enum AuthError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case networkError(Error)
    case serverError(String)
    case decodingError
    case unauthorized
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .serverError(let message):
            return message
        case .decodingError:
            return "Failed to decode response"
        case .unauthorized:
            return "Unauthorized - please login again"
        }
    }
}

class AuthService {
    static let shared = AuthService()
    
    private let baseURL = "http://localhost:8080"
    
    private init() {}
    
    // MARK: - Email Verification Code
    
    /// Send email verification code for registration or login
    /// - Parameters:
    ///   - email: User's email address
    ///   - purpose: "register" or "login"
    func sendEmailVerificationCode(email: String, purpose: String) async throws -> VerificationCodeResponse {
        guard let url = URL(string: "\(baseURL)/api/v1/auth/email/send-code") else {
            throw AuthError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: String] = [
            "email": email,
            "purpose": purpose
        ]
        request.httpBody = try JSONEncoder().encode(body)
        
        return try await performRequest(request)
    }
    
    // MARK: - Registration
    
    /// Register with email and verification code
    func registerWithEmail(email: String, code: String) async throws -> AuthResponse {
        guard let url = URL(string: "\(baseURL)/api/v1/auth/register/email") else {
            throw AuthError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: String] = [
            "email": email,
            "code": code
        ]
        request.httpBody = try JSONEncoder().encode(body)
        
        return try await performRequest(request)
    }
    
    // MARK: - Login
    
    /// Login with email and verification code
    func loginWithEmailCode(email: String, code: String) async throws -> AuthResponse {
        guard let url = URL(string: "\(baseURL)/api/v1/auth/login/email") else {
            throw AuthError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: String] = [
            "email": email,
            "code": code
        ]
        request.httpBody = try JSONEncoder().encode(body)
        
        return try await performRequest(request)
    }
    
    /// Login with email and password
    func loginWithPassword(email: String, password: String) async throws -> AuthResponse {
        guard let url = URL(string: "\(baseURL)/api/v1/auth/login/password") else {
            throw AuthError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: String] = [
            "email": email,
            "password": password
        ]
        request.httpBody = try JSONEncoder().encode(body)
        
        return try await performRequest(request)
    }
    
    // MARK: - Password Management
    
    /// Set initial password after registration and login
    func setPassword(password: String, token: String, userId: String) async throws {
        guard let url = URL(string: "\(baseURL)/api/v1/auth/password/set") else {
            throw AuthError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(userId, forHTTPHeaderField: "X-User-ID")
        
        let body: [String: String] = [
            "password": password
        ]
        request.httpBody = try JSONEncoder().encode(body)
        
        let _: VerificationCodeResponse = try await performRequest(request)
    }
    
    /// Change password when already logged in
    func changePassword(oldPassword: String, newPassword: String, token: String, userId: String) async throws {
        guard let url = URL(string: "\(baseURL)/api/v1/auth/password/change") else {
            throw AuthError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(userId, forHTTPHeaderField: "X-User-ID")
        
        let body: [String: String] = [
            "oldPassword": oldPassword,
            "newPassword": newPassword
        ]
        request.httpBody = try JSONEncoder().encode(body)
        
        let _: VerificationCodeResponse = try await performRequest(request)
    }
    
    /// Request password reset (forgot password)
    func requestPasswordReset(email: String) async throws {
        guard let url = URL(string: "\(baseURL)/api/v1/auth/password/reset-request") else {
            throw AuthError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: String] = [
            "email": email
        ]
        request.httpBody = try JSONEncoder().encode(body)
        
        let _: VerificationCodeResponse = try await performRequest(request)
    }
    
    /// Reset password with verification code
    func resetPassword(email: String, code: String, newPassword: String) async throws -> AuthResponse {
        guard let url = URL(string: "\(baseURL)/api/v1/auth/password/reset") else {
            throw AuthError.invalidURL
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
        
        return try await performRequest(request)
    }
    
    // MARK: - Helper Methods
    
    private func performRequest<T: Decodable>(_ request: URLRequest) async throws -> T {
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw AuthError.invalidResponse
            }
            
            // Success status codes
            if (200...299).contains(httpResponse.statusCode) {
                do {
                    let result = try JSONDecoder().decode(T.self, from: data)
                    return result
                } catch {
                    // Failed to decode response
                    throw AuthError.decodingError
                }
            } else if httpResponse.statusCode == 401 {
                throw AuthError.unauthorized
            } else {
                // Try to decode error response
                if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data),
                   let errorMessage = errorResponse.error ?? errorResponse.message {
                    throw AuthError.serverError(errorMessage)
                }
                
                if let dataString = String(data: data, encoding: .utf8) {
                    throw AuthError.serverError(dataString)
                }
                
                throw AuthError.serverError("Server error: \(httpResponse.statusCode)")
            }
        } catch let error as AuthError {
            throw error
        } catch {
            throw AuthError.networkError(error)
        }
    }
}
