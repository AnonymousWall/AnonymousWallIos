//
//  Coordinator.swift
//  AnonymousWallIos
//
//  Coordinator protocol for navigation management
//

import SwiftUI

/// Protocol defining the basic coordinator contract
@MainActor
protocol Coordinator: AnyObject, ObservableObject {
    associatedtype Destination: Hashable
    
    /// Navigation path for managing the navigation stack
    var path: NavigationPath { get set }
    
    /// Navigate to a specific destination
    func navigate(to destination: Destination)
    
    /// Pop to root of navigation stack
    func popToRoot()
    
    /// Pop back one level
    func pop()
}

/// Default implementations for common coordinator operations
extension Coordinator {
    func popToRoot() {
        path = NavigationPath()
    }
    
    func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }
    
    /// Registers an observer that resets `path` to root when `.resetNavigation` is posted.
    ///
    /// Pass an optional `onReset` closure for coordinator-specific cleanup (e.g. clearing
    /// a selected item).  The closure is called on `@MainActor` immediately after `path` is
    /// cleared, so it is safe to mutate `@Published` properties inside it.
    ///
    /// - Returns: An opaque observer token. Store it in the coordinator and pass it to
    ///   `NotificationCenter.default.removeObserver(_:)` in `deinit`.
    func makeNavigationResetObserver(onReset: (() -> Void)? = nil) -> NSObjectProtocol {
        NotificationCenter.default.addObserver(
            forName: .resetNavigation,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.path = NavigationPath()
                onReset?()
            }
        }
    }
}

extension Notification.Name {
    /// Posted when all coordinators should reset their navigation stacks to root.
    /// Fired on app foreground when the user's session is no longer valid.
    static let resetNavigation = Notification.Name("resetNavigation")
}
