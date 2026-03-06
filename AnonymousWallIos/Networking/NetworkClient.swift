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
    
    /// Closure invoked on @MainActor when the server returns 401.
    /// Configured at app startup to trigger logout.
    private var onUnauthorized: (@MainActor () -> Void)?
    
    /// Coalesces concurrent refresh attempts so only one runs at a time.
    private var refreshTask: Task<Bool, Never>?
    
    private init(session: URLSession = .shared) {
        self.session = session
    }
    
    /// Configure the handler for blocked user responses
    func configureBlockedUserHandler(onBlockedUser: @escaping @MainActor () -> Void) {
        blockedUserHandler.onBlockedUser = onBlockedUser
    }
    
    /// Configure the handler for unauthorized (401) responses
    func configureUnauthorizedHandler(onUnauthorized: @escaping @MainActor () -> Void) {
        self.onUnauthorized = onUnauthorized
    }
    
    /// Triggers logout for 401 responses from services that bypass executeRequest (e.g. multipart uploads).
    /// Attempts a silent token refresh before forcing logout.
    func handleUnauthorized() async {
        let refreshed = await refreshAccessToken()
        if !refreshed {
            await MainActor.run { onUnauthorized?() }
        }
    }
    
    // MARK: - Token Refresh
    
    /// Attempts a silent token refresh. Coalesces concurrent calls so only one refresh runs at a time.
    /// - Returns: `true` if the refresh succeeded and new tokens were saved to Keychain, `false` otherwise.
    func refreshAccessToken() async -> Bool {
        // If a refresh is already in progress, wait for its result
        if let existing = refreshTask {
            return await existing.value
        }
        
        let task = Task<Bool, Never> {
            defer { self.refreshTask = nil }
            return await self.performTokenRefresh()
        }
        
        refreshTask = task
        return await task.value
    }
    
    private func performTokenRefresh() async -> Bool {
        guard let refreshToken = KeychainHelper.shared.get(config.refreshTokenKey) else {
            Logger.auth.debug("No refresh token found in Keychain — cannot refresh")
            return false
        }
        
        guard let url = URL(string: config.fullAPIBaseURL + "/auth/refresh") else {
            return false
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONEncoder().encode(TokenRefreshRequest(refreshToken: refreshToken))
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                Logger.auth.debug("Token refresh failed — server returned non-200 response")
                return false
            }
            
            let tokenResponse = try JSONDecoder().decode(TokenRefreshResponse.self, from: data)
            KeychainHelper.shared.save(tokenResponse.accessToken, forKey: config.authTokenKey)
            KeychainHelper.shared.save(tokenResponse.refreshToken, forKey: config.refreshTokenKey)
            Logger.auth.debug("Token refresh succeeded — new tokens saved to Keychain")
            return true
        } catch {
            Logger.auth.debug("Token refresh failed with error: \(error.localizedDescription)")
            return false
        }
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
                // Attempt silent token refresh before giving up
                let refreshed = await refreshAccessToken()
                
                if refreshed {
                    // Rebuild the request with the new access token and retry once
                    var retryRequest = request
                    if let newToken = KeychainHelper.shared.get(config.authTokenKey) {
                        retryRequest.setValue(
                            "Bearer \(newToken)",
                            forHTTPHeaderField: "Authorization")
                    }
                    // Re-attach X-User-Id header if present on original request
                    if let userId = request.value(forHTTPHeaderField: "X-User-Id") {
                        retryRequest.setValue(userId, forHTTPHeaderField: "X-User-Id")
                    }
                    
                    let (retryData, retryResponse) = try await session.data(for: retryRequest)
                    guard let retryHttpResponse = retryResponse as? HTTPURLResponse else {
                        throw NetworkError.invalidResponse
                    }
                    // If the retried request also fails, force logout — do not refresh again
                    if retryHttpResponse.statusCode == HTTPStatus.unauthorized {
                        await MainActor.run { onUnauthorized?() }
                        throw NetworkError.unauthorized
                    }
                    // Treat the retry response as the authoritative result
                    if HTTPStatus.successRange ~= retryHttpResponse.statusCode {
                        do {
                            let decoder = JSONDecoder()
                            let result = try decoder.decode(T.self, from: retryData)
                            return result
                        } catch {
                            throw NetworkError.decodingError(error)
                        }
                    }
                    let errorMessage = extractErrorMessage(from: retryData) ?? "Server error: \(retryHttpResponse.statusCode)"
                    throw NetworkError.serverError(errorMessage)
                } else {
                    // Refresh failed — session truly expired, force logout
                    await MainActor.run { onUnauthorized?() }
                    throw NetworkError.unauthorized
                }
                
            case HTTPStatus.forbidden:
                // Only trigger the blocked-user logout flow if the response body
                // explicitly indicates the account is blocked.  A generic 403
                // (e.g. content-type rejection, permission error) must not force logout.
                let isBlockedAccount = isBlockedUserResponse(data)
                if isBlockedAccount {
                    await blockedUserHandler.handleBlockedUser()
                }
                throw NetworkError.forbidden
                
            case HTTPStatus.notFound:
                throw NetworkError.notFound
                
            case 409:
                let errorMessage = extractErrorMessage(from: data) ?? "Conflict"
                throw NetworkError.conflict(errorMessage)
                
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
    
    /// Returns true only when a 403 response body explicitly signals the user account is blocked.
    /// This prevents content-type mismatches or regular permission errors from triggering logout.
    private func isBlockedUserResponse(_ data: Data) -> Bool {
        let bodyText = String(data: data, encoding: .utf8)?.lowercased() ?? ""
        return bodyText.contains("blocked")
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
