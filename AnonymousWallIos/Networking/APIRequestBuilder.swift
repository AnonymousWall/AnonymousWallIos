//
//  APIRequestBuilder.swift
//  AnonymousWallIos
//
//  Centralized request builder for consistent API request construction
//

import Foundation

/// Builder for constructing URLRequest objects with consistent headers and configuration
class APIRequestBuilder {
    private let config = AppConfiguration.shared
    private var path: String = ""
    private var method: HTTPMethod = .GET
    private var queryItems: [URLQueryItem] = []
    private var body: Data?
    private var token: String?
    private var userId: String?
    private var additionalHeaders: [String: String] = [:]
    
    // MARK: - Builder Methods
    
    /// Set the API endpoint path
    /// - Parameter path: The endpoint path (e.g., "/posts", "/auth/login")
    /// - Returns: Self for chaining
    func setPath(_ path: String) -> APIRequestBuilder {
        self.path = path
        return self
    }
    
    /// Set the HTTP method
    /// - Parameter method: The HTTP method (GET, POST, etc.)
    /// - Returns: Self for chaining
    func setMethod(_ method: HTTPMethod) -> APIRequestBuilder {
        self.method = method
        return self
    }
    
    /// Add query parameters to the URL
    /// - Parameter items: Array of URLQueryItem
    /// - Returns: Self for chaining
    func addQueryItems(_ items: [URLQueryItem]) -> APIRequestBuilder {
        self.queryItems.append(contentsOf: items)
        return self
    }
    
    /// Set the request body with JSON encoding
    /// - Parameter body: Encodable object to be JSON-encoded
    /// - Returns: Self for chaining
    /// - Throws: Encoding errors
    func setBody<T: Encodable>(_ body: T) throws -> APIRequestBuilder {
        self.body = try JSONEncoder().encode(body)
        return self
    }
    
    /// Set the authentication token
    /// - Parameter token: Bearer token for authorization
    /// - Returns: Self for chaining
    func setToken(_ token: String) -> APIRequestBuilder {
        self.token = token
        return self
    }
    
    /// Set the user ID header
    /// - Parameter userId: User ID for X-User-Id header
    /// - Returns: Self for chaining
    func setUserId(_ userId: String) -> APIRequestBuilder {
        self.userId = userId
        return self
    }
    
    /// Add a custom header
    /// - Parameters:
    ///   - value: Header value
    ///   - field: Header field name
    /// - Returns: Self for chaining
    func addHeader(value: String, forField field: String) -> APIRequestBuilder {
        self.additionalHeaders[field] = value
        return self
    }
    
    // MARK: - Build
    
    /// Build the final URLRequest
    /// - Returns: Configured URLRequest
    /// - Throws: NetworkError.invalidURL if URL construction fails
    func build() throws -> URLRequest {
        // Construct URL
        let urlString = "\(config.fullAPIBaseURL)\(path)"
        
        var components = URLComponents(string: urlString)
        if !queryItems.isEmpty {
            components?.queryItems = queryItems
        }
        
        guard let url = components?.url else {
            throw NetworkError.invalidURL
        }
        
        // Create request
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        
        // Set standard headers
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Set authentication headers if provided
        if let token = token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        if let userId = userId {
            request.setValue(userId, forHTTPHeaderField: "X-User-Id")
        }
        
        // Set additional headers
        for (field, value) in additionalHeaders {
            request.setValue(value, forHTTPHeaderField: field)
        }
        
        // Set body if provided
        if let body = body {
            request.httpBody = body
        }
        
        return request
    }
}
