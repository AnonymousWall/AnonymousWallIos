//
//  PushNotificationDestination.swift
//  AnonymousWallIos
//
//  Typed destination for push notification deep links
//

import Foundation

enum PushNotificationDestination: Equatable {
    case post(UUID, wall: String)
    case internship(UUID)
    case marketplace(UUID)
    case chat(conversationId: String, senderUserId: String)
}
