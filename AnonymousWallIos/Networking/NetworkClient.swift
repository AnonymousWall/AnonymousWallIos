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

    private actor RefreshCoordinator {
        private var currentTask: Task<Bool, Never>?

        func refresh(using performer: @escaping () async -> Bool) async -> Bool {
            if let existing = currentTask {
                return await existing.value
            }
            let task = Task<Bool, Never> {
                let result = await performer()
                return result
            }
            currentTask = task
            let result = await task.value
            currentTask = nil
            return result
        }
    }
    
    private let session: URLSession
    private let config = AppConfiguration.shared
    private let blockedUserHandler = BlockedUserHandler()
    private let refreshCoordinator = RefreshCoordinator()
    
    /// Closure invoked on @MainActor when the server returns 401.
    /// Configured at app startup to trigger logout.
    private var onUnauthorized: (@MainActor () -> Void)?
    
    /// Called on @MainActor after every successful silent refresh.
    /// Wired in AnonymousWallIosApp to update authState.authToken and
    /// post the .tokenRefreshed notification for ChatRepository.
    private var onTokenRefreshed: ((String) -> Void)?

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

    func configureTokenRefreshHandler(onTokenRefreshed: @escaping (String) -> Void) {
        self.onTokenRefreshed = onTokenRefreshed
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

    // MARK: - Token Refresh

    func refreshAccessToken() async -> Bool {
        return await refreshCoordinator.refresh(using: performTokenRefresh)
    }

    private func performTokenRefresh() async -> Bool {
        guard let refreshToken = KeychainHelper.shared.get(config.refreshTokenKey) else {
            Logger.auth.debug("No refresh token in Keychain — cannot refresh")
            return false
        }

        guard let url = URL(string: config.fullAPIBaseURL + "/auth/refresh") else {
            return false
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            request.httpBody = try JSONEncoder().encode(
                TokenRefreshRequest(refreshToken: refreshToken)
            )
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == HTTPStatus.ok else {
                Logger.auth.debug("Token refresh failed — non-200 response")
                return false
            }

            let tokenResponse = try JSONDecoder().decode(TokenRefreshResponse.self, from: data)
            KeychainHelper.shared.save(tokenResponse.accessToken, forKey: config.authTokenKey)
            KeychainHelper.shared.save(tokenResponse.refreshToken, forKey: config.refreshTokenKey)

            let newToken = tokenResponse.accessToken
            Task { @MainActor in
                self.onTokenRefreshed?(newToken)
            }

            Logger.auth.debug("Token refresh succeeded — new tokens saved")
            return true
        } catch {
            Logger.auth.debug("Token refresh error: \(error.localizedDescription)")
            return false
        }
    }

    // MARK: - Multipart Upload

    /// Executes a pre-built multipart URLRequest with 401 refresh-and-retry.
    /// PostService, MarketplaceService, and ChatService must use this for all
    /// multipart uploads instead of creating their own URLSession.
    func performMultipartRequest(_ urlRequest: URLRequest) async throws -> Data {
        let (data, response) = try await executeMultipart(urlRequest)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.serverError("Invalid response")
        }

        if HTTPStatus.successRange ~= httpResponse.statusCode {
            return data
        }

        if httpResponse.statusCode == HTTPStatus.unauthorized {
            let refreshed = await refreshAccessToken()

            if refreshed, let newToken = KeychainHelper.shared.get(config.authTokenKey) {
                var retryRequest = urlRequest
                retryRequest.setValue("Bearer \(newToken)", forHTTPHeaderField: "Authorization")

                let (retryData, retryResponse) = try await executeMultipart(retryRequest)
                guard let retryHttp = retryResponse as? HTTPURLResponse else {
                    throw NetworkError.serverError("Invalid response")
                }

                if retryHttp.statusCode == HTTPStatus.unauthorized {
                    await MainActor.run { onUnauthorized?() }
                    throw NetworkError.unauthorized
                }
                if HTTPStatus.successRange ~= retryHttp.statusCode {
                    return retryData
                }
                let message = String(data: retryData, encoding: .utf8) ?? "Server error"
                throw NetworkError.serverError(message)
            } else {
                await MainActor.run { onUnauthorized?() }
                throw NetworkError.unauthorized
            }
        }

        if httpResponse.statusCode == HTTPStatus.forbidden {
            throw NetworkError.forbidden
        }
        let message = String(data: data, encoding: .utf8) ?? "Server error"
        throw NetworkError.serverError(message)
    }

    private func executeMultipart(_ urlRequest: URLRequest) async throws -> (Data, URLResponse) {
        let sessionConfig = URLSessionConfiguration.ephemeral
        sessionConfig.waitsForConnectivity = true
        let session = URLSession(configuration: sessionConfig)
        defer { session.invalidateAndCancel() }
        return try await session.data(for: urlRequest)
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
                if T.self == EmptyResponse.self,
                   data.isEmpty,
                   let emptyResponse = EmptyResponse() as? T {
                    return emptyResponse
                }
                do {
                    let decoder = JSONDecoder()
                    let result = try decoder.decode(T.self, from: data)
                    return result
                } catch {
                    throw NetworkError.decodingError(error)
                }
                
            case HTTPStatus.unauthorized:
                let refreshed = await refreshAccessToken()

                if refreshed {
                    var retryRequest = request
                    if let newToken = KeychainHelper.shared.get(config.authTokenKey) {
                        retryRequest.setValue(
                            "Bearer \(newToken)",
                            forHTTPHeaderField: "Authorization"
                        )
                    }
                    if let userId = request.value(forHTTPHeaderField: "X-User-Id") {
                        retryRequest.setValue(userId, forHTTPHeaderField: "X-User-Id")
                    }

                    let (retryData, retryResponse) = try await session.data(for: retryRequest)
                    guard let retryHttpResponse = retryResponse as? HTTPURLResponse else {
                        throw NetworkError.invalidResponse
                    }

                    if retryHttpResponse.statusCode == HTTPStatus.unauthorized {
                        await MainActor.run { onUnauthorized?() }
                        throw NetworkError.unauthorized
                    }

                    if HTTPStatus.successRange ~= retryHttpResponse.statusCode {
                        if T.self == EmptyResponse.self,
                           retryData.isEmpty,
                           let emptyResponse = EmptyResponse() as? T {
                            return emptyResponse
                        }
                        do {
                            return try JSONDecoder().decode(T.self, from: retryData)
                        } catch {
                            throw NetworkError.decodingError(error)
                        }
                    }

                    let errorMessage = extractErrorMessage(from: retryData)
                        ?? "Server error: \(retryHttpResponse.statusCode)"
                    throw NetworkError.serverError(errorMessage)
                } else {
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

private struct TokenRefreshRequest: Codable {
    let refreshToken: String
}

private struct TokenRefreshResponse: Codable {
    let accessToken: String
    let refreshToken: String
}
