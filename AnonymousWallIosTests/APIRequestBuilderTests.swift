//
//  APIRequestBuilderTests.swift
//  AnonymousWallIosTests
//
//  Tests for APIRequestBuilder to ensure correct request construction
//

import Testing
@testable import AnonymousWallIos
import Foundation

struct APIRequestBuilderTests {
    
    // MARK: - Basic Request Building
    
    @Test func testBasicGETRequest() throws {
        let request = try APIRequestBuilder()
            .setPath("/posts")
            .setMethod(.GET)
            .build()
        
        #expect(request.httpMethod == "GET")
        #expect(request.url?.path.contains("/posts") == true)
        #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
    }
    
    @Test func testPOSTRequestWithBody() throws {
        let body = ["email": "test@example.com", "code": "123456"]
        let request = try APIRequestBuilder()
            .setPath("/auth/login/email")
            .setMethod(.POST)
            .setBody(body)
            .build()
        
        #expect(request.httpMethod == "POST")
        #expect(request.httpBody != nil)
        #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
    }
    
    @Test func testPATCHRequest() throws {
        let request = try APIRequestBuilder()
            .setPath("/posts/123/hide")
            .setMethod(.PATCH)
            .build()
        
        #expect(request.httpMethod == "PATCH")
    }
    
    @Test func testDELETERequest() throws {
        let request = try APIRequestBuilder()
            .setPath("/posts/123")
            .setMethod(.DELETE)
            .build()
        
        #expect(request.httpMethod == "DELETE")
    }
    
    // MARK: - Authentication Headers
    
    @Test func testAuthorizationHeader() throws {
        let token = "test-token-12345"
        let request = try APIRequestBuilder()
            .setPath("/posts")
            .setMethod(.GET)
            .setToken(token)
            .build()
        
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer test-token-12345")
    }
    
    @Test func testUserIdHeader() throws {
        let userId = "user-id-12345"
        let request = try APIRequestBuilder()
            .setPath("/posts")
            .setMethod(.GET)
            .setUserId(userId)
            .build()
        
        #expect(request.value(forHTTPHeaderField: "X-User-Id") == "user-id-12345")
    }
    
    @Test func testBothAuthenticationHeaders() throws {
        let token = "test-token"
        let userId = "test-user-id"
        
        let request = try APIRequestBuilder()
            .setPath("/posts")
            .setMethod(.POST)
            .setToken(token)
            .setUserId(userId)
            .build()
        
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer test-token")
        #expect(request.value(forHTTPHeaderField: "X-User-Id") == "test-user-id")
    }
    
    // MARK: - Query Parameters
    
    @Test func testQueryParameters() throws {
        let queryItems = [
            URLQueryItem(name: "page", value: "1"),
            URLQueryItem(name: "limit", value: "20"),
            URLQueryItem(name: "sort", value: "NEWEST")
        ]
        
        let request = try APIRequestBuilder()
            .setPath("/posts")
            .setMethod(.GET)
            .addQueryItems(queryItems)
            .build()
        
        let urlString = request.url?.absoluteString ?? ""
        #expect(urlString.contains("page=1"))
        #expect(urlString.contains("limit=20"))
        #expect(urlString.contains("sort=NEWEST"))
    }
    
    // MARK: - Custom Headers
    
    @Test func testAdditionalHeaders() throws {
        let request = try APIRequestBuilder()
            .setPath("/posts")
            .setMethod(.GET)
            .addHeader(value: "custom-value", forField: "X-Custom-Header")
            .build()
        
        #expect(request.value(forHTTPHeaderField: "X-Custom-Header") == "custom-value")
    }
    
    @Test func testMultipleAdditionalHeaders() throws {
        let request = try APIRequestBuilder()
            .setPath("/posts")
            .setMethod(.GET)
            .addHeader(value: "value1", forField: "X-Header-1")
            .addHeader(value: "value2", forField: "X-Header-2")
            .build()
        
        #expect(request.value(forHTTPHeaderField: "X-Header-1") == "value1")
        #expect(request.value(forHTTPHeaderField: "X-Header-2") == "value2")
    }
    
    // MARK: - Body Encoding
    
    @Test func testBodyEncodingWithDictionary() throws {
        let body = ["key1": "value1", "key2": "value2"]
        let request = try APIRequestBuilder()
            .setPath("/posts")
            .setMethod(.POST)
            .setBody(body)
            .build()
        
        #expect(request.httpBody != nil)
        
        // Verify the body can be decoded
        if let data = request.httpBody {
            let decoded = try JSONDecoder().decode([String: String].self, from: data)
            #expect(decoded["key1"] == "value1")
            #expect(decoded["key2"] == "value2")
        }
    }
    
    @Test func testBodyEncodingWithCustomStruct() throws {
        struct TestBody: Codable {
            let title: String
            let content: String
            let wall: String
        }
        
        let body = TestBody(title: "Test Title", content: "Test Content", wall: "campus")
        let request = try APIRequestBuilder()
            .setPath("/posts")
            .setMethod(.POST)
            .setBody(body)
            .build()
        
        #expect(request.httpBody != nil)
        
        if let data = request.httpBody {
            let decoded = try JSONDecoder().decode(TestBody.self, from: data)
            #expect(decoded.title == "Test Title")
            #expect(decoded.content == "Test Content")
            #expect(decoded.wall == "campus")
        }
    }
    
    // MARK: - URL Construction
    
    @Test func testURLConstructionWithBasePath() throws {
        let request = try APIRequestBuilder()
            .setPath("/posts")
            .setMethod(.GET)
            .build()
        
        let urlString = request.url?.absoluteString ?? ""
        #expect(urlString.contains("/api/v1/posts"))
    }
    
    @Test func testURLConstructionWithPathParameter() throws {
        let postId = "abc123"
        let request = try APIRequestBuilder()
            .setPath("/posts/\(postId)")
            .setMethod(.GET)
            .build()
        
        let urlString = request.url?.absoluteString ?? ""
        #expect(urlString.contains("/posts/abc123"))
    }
    
    // MARK: - Method Chaining
    
    @Test func testCompleteRequestBuilding() throws {
        // Test a complete request with all features
        let body = ["email": "test@example.com", "password": "password123"]
        let request = try APIRequestBuilder()
            .setPath("/auth/login/password")
            .setMethod(.POST)
            .setBody(body)
            .setToken("my-token")
            .setUserId("my-user-id")
            .addHeader(value: "test-value", forField: "X-Test-Header")
            .build()
        
        #expect(request.httpMethod == "POST")
        #expect(request.httpBody != nil)
        #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer my-token")
        #expect(request.value(forHTTPHeaderField: "X-User-Id") == "my-user-id")
        #expect(request.value(forHTTPHeaderField: "X-Test-Header") == "test-value")
    }
    
    // MARK: - Edge Cases
    
    @Test func testRequestWithoutToken() throws {
        // Some endpoints (like registration) don't require a token
        let request = try APIRequestBuilder()
            .setPath("/auth/register/email")
            .setMethod(.POST)
            .build()
        
        #expect(request.value(forHTTPHeaderField: "Authorization") == nil)
    }
    
    @Test func testRequestWithoutUserId() throws {
        let request = try APIRequestBuilder()
            .setPath("/auth/register/email")
            .setMethod(.POST)
            .build()
        
        #expect(request.value(forHTTPHeaderField: "X-User-Id") == nil)
    }
    
    @Test func testRequestWithoutBody() throws {
        let request = try APIRequestBuilder()
            .setPath("/posts")
            .setMethod(.GET)
            .build()
        
        #expect(request.httpBody == nil)
    }
    
    @Test func testEmptyQueryItems() throws {
        let request = try APIRequestBuilder()
            .setPath("/posts")
            .setMethod(.GET)
            .addQueryItems([])
            .build()
        
        #expect(request.url != nil)
    }
}
