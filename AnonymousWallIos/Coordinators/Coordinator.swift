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
}
