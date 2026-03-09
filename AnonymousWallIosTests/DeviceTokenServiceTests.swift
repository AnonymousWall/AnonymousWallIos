//
//  DeviceTokenServiceTests.swift
//  AnonymousWallIosTests
//

import Testing
@testable import AnonymousWallIos
import Foundation

@MainActor
struct DeviceTokenServiceTests {

    @Test func testRegisterTokenCallsNetworkClient() async throws {
        let networkClient = MockDeviceTokenNetworkClient()
        let service = DeviceTokenService(networkClient: networkClient)
        let authState = AuthState(loadPersistedState: false)
        authState.authToken = "access-token"
        authState.currentUser = User(
            id: "user-123",
            email: "user@example.com",
            profileName: "Tester",
            isVerified: true,
            passwordSet: true,
            createdAt: "2026-03-08T00:00:00Z"
        )

        await service.registerToken("apns-token", authState: authState)

        #expect(networkClient.performWithoutResponseCallCount == 1)
        #expect(networkClient.lastRequest?.url?.path == "/api/v1/devices/register")
        #expect(networkClient.lastRequest?.value(forHTTPHeaderField: "Authorization") == "Bearer access-token")
        #expect(networkClient.lastRequest?.value(forHTTPHeaderField: "X-User-Id") == "user-123")
    }

    @Test func testRegisterTokenSkipsRequestWithoutAuthenticatedUser() async throws {
        let networkClient = MockDeviceTokenNetworkClient()
        let service = DeviceTokenService(networkClient: networkClient)
        let authState = AuthState(loadPersistedState: false)

        await service.registerToken("apns-token", authState: authState)

        #expect(networkClient.performWithoutResponseCallCount == 0)
    }
}

private final class MockDeviceTokenNetworkClient: NetworkClientProtocol {
    var performWithoutResponseCallCount = 0
    var lastRequest: URLRequest?

    func performRequest<T>(
        _ request: URLRequest,
        retryPolicy: RetryPolicy
    ) async throws -> T where T: Decodable {
        throw NetworkError.serverError("Unexpected request")
    }

    func performRequestWithoutResponse(
        _ request: URLRequest,
        retryPolicy: RetryPolicy
    ) async throws {
        performWithoutResponseCallCount += 1
        lastRequest = request
    }
}
