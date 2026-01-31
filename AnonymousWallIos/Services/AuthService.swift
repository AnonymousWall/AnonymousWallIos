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
        }
    }
}

class AuthService {
    static let shared = AuthService()
    
    // TODO: Replace with actual backend URL
    private let baseURL = "https://api.example.com" // Replace with your actual backend URL
    
    private init() {}
    
    // Register with email - sends verification code
    func register(email: String) async throws -> VerificationCodeResponse {
        guard let url = URL(string: "\(baseURL)/auth/register") else {
            throw AuthError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["email": email]
        request.httpBody = try JSONEncoder().encode(body)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw AuthError.invalidResponse
            }
            
            if httpResponse.statusCode == 200 {
                let result = try JSONDecoder().decode(VerificationCodeResponse.self, from: data)
                return result
            } else {
                if let errorResponse = try? JSONDecoder().decode(VerificationCodeResponse.self, from: data) {
                    throw AuthError.serverError(errorResponse.message)
                }
                throw AuthError.invalidResponse
            }
        } catch let error as AuthError {
            throw error
        } catch {
            throw AuthError.networkError(error)
        }
    }
    
    // Login with email and verification code
    func login(email: String, verificationCode: String) async throws -> AuthResponse {
        guard let url = URL(string: "\(baseURL)/auth/login") else {
            throw AuthError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = [
            "email": email,
            "verification_code": verificationCode
        ]
        request.httpBody = try JSONEncoder().encode(body)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw AuthError.invalidResponse
            }
            
            if httpResponse.statusCode == 200 {
                let result = try JSONDecoder().decode(AuthResponse.self, from: data)
                return result
            } else {
                if let errorResponse = try? JSONDecoder().decode(AuthResponse.self, from: data) {
                    throw AuthError.serverError(errorResponse.message)
                }
                throw AuthError.invalidResponse
            }
        } catch let error as AuthError {
            throw error
        } catch {
            throw AuthError.networkError(error)
        }
    }
    
    // Request verification code for existing email
    func requestVerificationCode(email: String) async throws -> VerificationCodeResponse {
        guard let url = URL(string: "\(baseURL)/auth/request-code") else {
            throw AuthError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["email": email]
        request.httpBody = try JSONEncoder().encode(body)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw AuthError.invalidResponse
            }
            
            if httpResponse.statusCode == 200 {
                let result = try JSONDecoder().decode(VerificationCodeResponse.self, from: data)
                return result
            } else {
                if let errorResponse = try? JSONDecoder().decode(VerificationCodeResponse.self, from: data) {
                    throw AuthError.serverError(errorResponse.message)
                }
                throw AuthError.invalidResponse
            }
        } catch let error as AuthError {
            throw error
        } catch {
            throw AuthError.networkError(error)
        }
    }
}
