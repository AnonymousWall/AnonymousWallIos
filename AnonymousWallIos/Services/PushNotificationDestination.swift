//
//  PushNotificationDestination.swift
//  AnonymousWallIos
//
//  Typed destination for push notification deep links
//

import Foundation

enum PushNotificationDestination {
    case post(UUID)
    case internship(UUID)
    case marketplace(UUID)
}
