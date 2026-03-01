//
//  NotificationService.swift
//  AnonymousWallIos
//
//  Requests notification permission and registers with APNs
//

import UIKit
import UserNotifications

@MainActor
class NotificationService: ObservableObject {

    static let shared = NotificationService()

    @Published var permissionGranted: Bool = false

    private init() {}

    /// Call on app launch after user is authenticated.
    func requestPermissionAndRegister() async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()

        switch settings.authorizationStatus {
        case .notDetermined:
            let granted = try? await center.requestAuthorization(options: [.alert, .sound, .badge])
            permissionGranted = granted ?? false
            if permissionGranted {
                registerWithAPNs()
            }
        case .authorized, .provisional:
            permissionGranted = true
            registerWithAPNs()
        case .denied, .ephemeral:
            permissionGranted = false
        @unknown default:
            break
        }
    }

    private func registerWithAPNs() {
        UIApplication.shared.registerForRemoteNotifications()
    }
}
