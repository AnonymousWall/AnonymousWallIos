//
//  NetworkClient.swift
//  AnonymousWallIos
//
//  Network layer abstraction
//

import Foundation

protocol NetworkClientProtocol {
    func performRequest<T: Decodable>(_ request: URLRequest, retryPolicy: RetryPolicy) async throws -> T
    func performRequestWithoutResponse(_ request: URLRequest, retryPolicy: RetryPolicy) async throws
}

class NetworkClient: NetworkClientProtocol {
    static let shared = NetworkClient()
    
    private let session: URLSession
    private let config = AppConfiguration.shared
    private let blockedUserHandler = BlockedUserHandler()
    
    private init(session: URLSession = .shared) {
        self.session = session
    }
    
    /// Configure the handler for blocked user responses
    func configureBlockedUserHandler(onBlockedUser: @escaping @MainActor () -> Void) {
        blockedUserHandler.onBlockedUser = onBlockedUser
    }
    
    // MARK: - Request Execution
    
    func performRequest<T: Decodable>(_ request: URLRequest, retryPolicy: RetryPolicy = .default) async throws -> T {
        return try await RetryUtility.execute(policy: retryPolicy) {
            try await self.executeRequest(request)
        }
    }
    
    func performRequestWithoutResponse(_ request: URLRequest, retryPolicy: RetryPolicy = .default) async throws {
        let _: EmptyResponse = try await performRequest(request, retryPolicy: retryPolicy)
    }
    
    // MARK: - Internal Request Execution
    
    private func executeRequest<T: Decodable>(_ request: URLRequest) async throws -> T {
        let modifiedRequest = request
        
        // Log request in development
        if config.enableNetworkLogging {
            logRequest(modifiedRequest)
        }
        
        do {
            let (data, response) = try await session.data(for: modifiedRequest)
            
            // Log response in development
            if config.enableNetworkLogging {
                logResponse(response, data: data)
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.invalidResponse
            }
            
            // Handle different status codes
            switch httpResponse.statusCode {
            case HTTPStatus.successRange:
                do {
                    let decoder = JSONDecoder()
                    let result = try decoder.decode(T.self, from: data)
                    return result
                } catch {
                    throw NetworkError.decodingError(error)
                }
                
            case HTTPStatus.unauthorized:
                throw NetworkError.unauthorized
                
            case HTTPStatus.forbidden:
                // Handle blocked user globally before throwing error
                await blockedUserHandler.handleBlockedUser()
                throw NetworkError.forbidden
                
            case HTTPStatus.notFound:
                throw NetworkError.notFound
                
            case HTTPStatus.timeout:
                throw NetworkError.timeout
                
            case HTTPStatus.serverErrorRange:
                // Server errors (5xx) - retriable
                let errorMessage = extractErrorMessage(from: data) ?? "Server error: \(httpResponse.statusCode)"
                throw NetworkError.serverError5xx(errorMessage, statusCode: httpResponse.statusCode)
                
            default:
                // Try to decode error response
                let errorMessage = extractErrorMessage(from: data) ?? "Server error: \(httpResponse.statusCode)"
                throw NetworkError.serverError(errorMessage)
            }
            
        } catch let error as NetworkError {
            throw error
        } catch let error as URLError {
            // Handle URL errors
            if error.code == .cancelled {
                throw NetworkError.cancelled
            } else if error.code == .notConnectedToInternet || error.code == .networkConnectionLost {
                throw NetworkError.noConnection
            } else if error.code == .timedOut {
                throw NetworkError.timeout
            }
            throw NetworkError.networkError(error)
        } catch {
            throw NetworkError.networkError(error)
        }
    }
    
    // MARK: - Helper Methods
    
    private func extractErrorMessage(from data: Data) -> String? {
        // Try to decode as ErrorResponse
        if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data),
           let errorMessage = errorResponse.error ?? errorResponse.message {
            return errorMessage
        }
        
        // Try to get as plain string
        if let dataString = String(data: data, encoding: .utf8), !dataString.isEmpty {
            return dataString
        }
        
        return nil
    }
    
    private func logRequest(_ request: URLRequest) {
        guard config.enableLogging else { return }
        
        let logger = Logger.network
        var message = "Request\n   URL: \(request.url?.absoluteString ?? "unknown")\n   Method: \(request.httpMethod ?? "GET")"
        
        if let headers = request.allHTTPHeaderFields, !headers.isEmpty {
            message += "\n   Headers: \(headers)"
        }
        
        if let body = request.httpBody,
           let bodyString = String(data: body, encoding: .utf8) {
            message += "\n   Body: \(bodyString)"
        }
        
        logger.debug(message)
    }
    
    private func logResponse(_ response: URLResponse, data: Data) {
        guard config.enableLogging else { return }
        
        if let httpResponse = response as? HTTPURLResponse {
            let logger = Logger.network
            var message = "Response\n   Status: \(httpResponse.statusCode)"
            
            if let dataString = String(data: data, encoding: .utf8) {
                message += "\n   Body: \(dataString)"
            }
            
            logger.debug(message)
        }
    }
}

// MARK: - Empty Response

private struct EmptyResponse: Codable {}
