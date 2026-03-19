//
//  ButtonStyles.swift
//  AnonymousWallIos
//
//  Custom button styles for enhanced UI engagement
//

import SwiftUI

/// A button style that scales down when pressed (bounce effect)
struct BounceButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}


extension ButtonStyle where Self == BounceButtonStyle {
    static var bounce: BounceButtonStyle {
        BounceButtonStyle()
    }
}
