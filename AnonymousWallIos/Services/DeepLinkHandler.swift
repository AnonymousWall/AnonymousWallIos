//
//  DeepLinkHandler.swift
//  AnonymousWallIos
//
//  Singleton that routes push notification taps to the correct post in the UI
//

import Foundation

@MainActor
class DeepLinkHandler: ObservableObject {

    static let shared = DeepLinkHandler()

    @Published var pendingPostId: UUID? = nil

    private var notificationObserver: NSObjectProtocol?

    private init() {
        notificationObserver = NotificationCenter.default.addObserver(
            forName: .pushNotificationTapped,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self,
                  let postId = notification.userInfo?["postId"] as? UUID else { return }
            Task { @MainActor [weak self] in
                self?.pendingPostId = postId
            }
        }
    }

    deinit {
        if let observer = notificationObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    /// Consumes and returns the pending post ID, clearing it after retrieval.
    func consume() -> UUID? {
        let id = pendingPostId
        pendingPostId = nil
        return id
    }
}
