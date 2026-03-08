//
//  DeviceTokenService.swift
//  AnonymousWallIos
//
//  Sends the APNs device token to the backend for push notification delivery
//

import Foundation

class DeviceTokenService {

    private let networkClient: NetworkClientProtocol

    init(networkClient: NetworkClientProtocol = NetworkClient.shared) {
        self.networkClient = networkClient
    }

    func registerToken(_ token: String, authState: AuthState) async {
        guard let jwtToken = await authState.authToken,
              let userId = await authState.currentUser?.id else { return }

        let body = RegisterDeviceRequest(deviceToken: token, platform: "IOS")

        do {
            let request = try APIRequestBuilder()
                .setPath("/devices/register")
                .setMethod(.POST)
                .setBody(body)
                .setToken(jwtToken)
                .setUserId(userId)
                .build()

            try await networkClient.performRequestWithoutResponse(request, retryPolicy: .default)
            Logger.network.info("Device token registered successfully")
        } catch NetworkError.unauthorized {
            Logger.network.warning("Failed to register device token: HTTP 401")
        } catch {
            Logger.network.error("Failed to register device token: \(error.localizedDescription)")
        }
    }
}

struct RegisterDeviceRequest: Codable {
    let deviceToken: String
    let platform: String
}
