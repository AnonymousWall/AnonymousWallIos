//
//  DeepLinkHandler.swift
//  AnonymousWallIos
//
//  Singleton that routes push notification taps to the correct screen in the UI
//

import Foundation

@MainActor
class DeepLinkHandler: ObservableObject {

    static let shared = DeepLinkHandler()

    @Published var pendingDestination: PushNotificationDestination? = nil

    private var notificationObserver: NSObjectProtocol?

    private init() {
        notificationObserver = NotificationCenter.default.addObserver(
            forName: .pushNotificationTapped,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self,
                  let destination = notification.userInfo?["destination"] as? PushNotificationDestination
            else { return }
            Task { @MainActor [weak self] in
                self?.pendingDestination = destination
            }
        }
    }

    deinit {
        if let observer = notificationObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    /// Consumes and returns the pending destination, clearing it after retrieval.
    func consume() -> PushNotificationDestination? {
        let destination = pendingDestination
        pendingDestination = nil
        return destination
    }
}
