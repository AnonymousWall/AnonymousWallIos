//
//  DeviceTokenService.swift
//  AnonymousWallIos
//
//  Sends the APNs device token to the backend for push notification delivery
//

import Foundation

class DeviceTokenService {

    private let networkClient: NetworkClient

    init(networkClient: NetworkClient = NetworkClient.shared) {
        self.networkClient = networkClient
    }

    func registerToken(_ token: String, authState: AuthState) async {
        guard let jwtToken = authState.authToken,
              let userId = authState.currentUser?.id else { return }

        let body = RegisterDeviceRequest(deviceToken: token, platform: "IOS")

        do {
            let request = try APIRequestBuilder()
                .setPath("/devices/register")
                .setMethod(.POST)
                .setBody(body)
                .setToken(jwtToken)
                .setUserId(userId)
                .build()

            try await networkClient.performRequestWithoutResponse(request)
        } catch {
            // Non-fatal — log and continue. Token will be re-sent on next launch.
            print("[DeviceToken] Failed to register token: \(error.localizedDescription)")
        }
    }
}

struct RegisterDeviceRequest: Codable {
    let deviceToken: String
    let platform: String
}
