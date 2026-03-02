//
//  AppDelegate.swift
//  AnonymousWallIos
//
//  UIApplicationDelegate for APNs registration and notification handling
//

import UIKit
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    // Called when APNs successfully registers — convert token Data to hex String
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        let tokenString = deviceToken.map { String(format: "%02x", $0) }.joined()
        NotificationCenter.default.post(
            name: .apnsTokenReceived,
            object: nil,
            userInfo: ["token": tokenString]
        )
    }

    // Called when APNs registration fails — log the error
    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("[APNs] Registration failed: \(error.localizedDescription)")
    }

    // Foreground notification — show banner even when app is open
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge])
    }

    // User tapped notification — extract payload and trigger deep link
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        let type = userInfo["type"] as? String

        switch type {
        case "COMMENT":
            if let postIdString = userInfo["postId"] as? String,
               let postId = UUID(uuidString: postIdString) {
                NotificationCenter.default.post(
                    name: .pushNotificationTapped,
                    object: nil,
                    userInfo: ["destination": PushNotificationDestination.post(postId)]
                )
            }

        case "INTERNSHIP_COMMENT":
            if let internshipIdString = userInfo["internshipId"] as? String,
               let internshipId = UUID(uuidString: internshipIdString) {
                NotificationCenter.default.post(
                    name: .pushNotificationTapped,
                    object: nil,
                    userInfo: ["destination": PushNotificationDestination.internship(internshipId)]
                )
            }

        case "MARKETPLACE_COMMENT":
            if let itemIdString = userInfo["itemId"] as? String,
               let itemId = UUID(uuidString: itemIdString) {
                NotificationCenter.default.post(
                    name: .pushNotificationTapped,
                    object: nil,
                    userInfo: ["destination": PushNotificationDestination.marketplace(itemId)]
                )
            }

        default:
            break
        }

        completionHandler()
    }
}

// MARK: - Notification Name Constants

extension Notification.Name {
    static let apnsTokenReceived      = Notification.Name("apnsTokenReceived")
    static let pushNotificationTapped = Notification.Name("pushNotificationTapped")
}
