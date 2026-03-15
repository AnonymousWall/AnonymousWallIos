//
//  MediaService.swift
//  AnonymousWallIos
//
//  Handles presign + direct OCI upload
//

import Foundation
import UIKit

struct PresignResponse: Decodable {
    let uploadUrl: String
    let objectName: String
}

struct PresignRequest: Encodable {
    let filename: String
    let folder: String
}

class MediaService: MediaServiceProtocol {
    static let shared = MediaService()
    private let networkClient = NetworkClient.shared
    private let config = AppConfiguration.shared
    private init() {}

    /// Step 1 — get a presigned OCI URL from the backend
    func presign(filename: String, folder: String, token: String) async throws -> PresignResponse {
        let body = PresignRequest(filename: filename, folder: folder)
        let request = try APIRequestBuilder()
            .setPath("/media/presign")
            .setMethod(.POST)
            .setToken(token)
            .setBody(body)
            .build()
        return try await networkClient.performRequest(request)
    }

    /// Step 2 — PUT the JPEG bytes directly to OCI (no auth header needed)
    func uploadDirect(to uploadUrl: String, jpeg: Data) async throws {
        guard let url = URL(string: uploadUrl) else {
            throw NetworkError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("image/jpeg", forHTTPHeaderField: "Content-Type")
        request.httpBody = jpeg
        request.timeoutInterval = 60

        let (_, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw NetworkError.serverError("OCI direct upload failed")
        }
    }

    /// Convenience — compress, presign, upload, return objectName
    func uploadImage(_ image: UIImage, folder: String, token: String) async throws -> String {
        let resized = image.resized(maxDimension: 1024)
        guard let jpeg = resized.jpegData(compressionQuality: 0.6) else {
            throw NetworkError.serverError("Failed to compress image")
        }
        let presign = try await presign(filename: "photo.jpg", folder: folder, token: token)
        try await uploadDirect(to: presign.uploadUrl, jpeg: jpeg)
        return presign.objectName
    }

    /// Upload multiple images, return objectNames
    func uploadImages(_ images: [UIImage], folder: String, token: String) async throws -> [String] {
        var objectNames: [String] = []
        for image in images.prefix(5) {
            let objectName = try await uploadImage(image, folder: folder, token: token)
            objectNames.append(objectName)
        }
        return objectNames
    }
}
