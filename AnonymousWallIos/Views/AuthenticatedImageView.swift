//
//  AuthenticatedImageView.swift
//  AnonymousWallIos
//
//  Reusable authenticated image view that fetches images from the private
//  OCI bucket via the media proxy endpoint with auth headers.
//
//  Task cancellation is handled automatically by the `.task(id:)` modifier:
//  the previous task is cancelled whenever `objectName` changes or the view
//  disappears, so no manual Task storage is needed.
//
//  Caching: URLSession.shared uses URLCache.shared by default, so responses
//  with HTTP cache headers from the server are cached automatically.
//

import SwiftUI

struct AuthenticatedImageView: View {
    /// Object name as returned by the API, e.g. "posts/uuid.jpg"
    let objectName: String
    var contentMode: ContentMode = .fill

    @EnvironmentObject var authState: AuthState
    @State private var imageData: Data?
    @State private var isLoading = true
    @State private var loadFailed = false

    var body: some View {
        Group {
            if let data = imageData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
            } else if isLoading {
                Rectangle()
                    .fill(Color.surfaceSecondary)
                    .overlay(ProgressView())
            } else {
                // Load failed — show neutral placeholder
                Rectangle()
                    .fill(Color.surfaceSecondary)
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundColor(.textSecondary)
                    )
            }
        }
        .task(id: objectName) {
            await loadImage()
        }
    }

    @MainActor
    private func loadImage() async {
        isLoading = true
        loadFailed = false
        imageData = nil

        guard !objectName.isEmpty,
              let token = authState.authToken,
              let userId = authState.currentUser?.id else {
            isLoading = false
            loadFailed = true
            return
        }

        // Percent-encode the object name so special characters are safe in URLs.
        // `.urlPathAllowed` preserves `/` separators (e.g. "posts/uuid.jpg") while
        // encoding characters that are not valid in a URL path component.
        let encodedName = objectName.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? objectName
        let path = "/media/\(encodedName)"

        do {
            let request = try APIRequestBuilder()
                .setPath(path)
                .setMethod(.GET)
                .setToken(token)
                .setUserId(userId)
                .build()

            let (data, response) = try await URLSession.shared.data(for: request)
            var statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1

            if statusCode == 401 {
                let refreshed = await NetworkClient.shared.refreshAccessToken()
                if refreshed == true,
                   let newToken = KeychainHelper.shared.get(
                    AppConfiguration.shared.authTokenKey) {
                    var retryRequest = request
                    retryRequest.setValue(
                        "Bearer \(newToken)",
                        forHTTPHeaderField: "Authorization")
                    let (retryData, retryResponse) = try await URLSession.shared.data(
                        for: retryRequest)
                    statusCode = (retryResponse as? HTTPURLResponse)?.statusCode ?? -1
                    if statusCode == 200 {
                        imageData = retryData
                        isLoading = false
                        return
                    }
                }
                isLoading = false
                loadFailed = true
                return
            }

            guard statusCode == 200 else {
                isLoading = false
                loadFailed = true
                return
            }

            imageData = data
        } catch {
            loadFailed = true
        }

        isLoading = false
    }
}
