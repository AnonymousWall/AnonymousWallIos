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

            let (_, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    Logger.network.info("Device token registered successfully")
                } else {
                    Logger.network.warning("Failed to register device token: HTTP \(httpResponse.statusCode)")
                }
            }
        } catch {
            Logger.network.error("Failed to register device token: \(error.localizedDescription)")
        }
    }
}

struct RegisterDeviceRequest: Codable {
    let deviceToken: String
    let platform: String
}
