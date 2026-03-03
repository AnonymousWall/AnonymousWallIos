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
        let userInfo = notification.request.content.userInfo
        let type = userInfo["type"] as? String

        if type == "CHAT_MESSAGE",
           let senderUserId = userInfo["senderUserId"] as? String,
           ActiveConversationTracker.shared.activeConversationId == senderUserId {
            completionHandler([]) // suppress — user is already in this chat
            return
        }

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

        if type == "CHAT_MESSAGE" {
            if let senderUserId = userInfo["senderUserId"] as? String {
                NotificationCenter.default.post(
                    name: .pushNotificationTapped,
                    object: nil,
                    userInfo: ["destination": PushNotificationDestination.chat(senderUserId: senderUserId)]
                )
            }
        } else {
            NotificationCenter.default.post(name: .openNotificationInbox, object: nil)
        }

        completionHandler()
    }
}

// MARK: - Notification Name Constants

extension Notification.Name {
    static let apnsTokenReceived      = Notification.Name("apnsTokenReceived")
    static let pushNotificationTapped = Notification.Name("pushNotificationTapped")
    static let openNotificationInbox  = Notification.Name("openNotificationInbox")
}
