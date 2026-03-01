//
//  DesignSystem.swift
//  AnonymousWallIos
//
//  Central design token definitions: colours, typography, spacing, and radii.
//

import SwiftUI

// MARK: - Color Tokens

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            assertionFailure("Invalid hex color format '\(hex)': expected 3, 6, or 8 hex characters.")
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }

    // Backgrounds
    static let appBackground     = Color(hex: "#0d0d0f")
    static let surfacePrimary    = Color(hex: "#17171a")
    static let surfaceSecondary  = Color(hex: "#1f1f23")
    static let surfaceTertiary   = Color(hex: "#26262b")

    // Borders
    static let borderSubtle      = Color.white.opacity(0.07)
    static let borderMedium      = Color.white.opacity(0.12)

    // Text
    static let textPrimary       = Color(hex: "#f2f2f5")
    static let textSecondary     = Color(hex: "#8a8a96")
    static let textTertiary      = Color(hex: "#55555e")

    // Accent — purple-pink brand
    static let accentPurple      = Color(hex: "#9b5de5")
    static let accentPink        = Color(hex: "#f72585")

    // Semantic accents
    static let accentBlue        = Color(hex: "#4895ef")
    static let accentGreen       = Color(hex: "#06d6a0")
    static let accentOrange      = Color(hex: "#fb8500")
    static let accentRed         = Color(hex: "#ef4444")
}

// MARK: - Gradient Tokens

extension LinearGradient {
    static let brandGradient = LinearGradient(
        colors: [.accentPurple, .accentPink],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - Typography Tokens

extension Font {
    // Display
    static let displayLarge  = Font.system(size: 28, weight: .bold,     design: .rounded)
    static let displayMedium = Font.system(size: 22, weight: .bold,     design: .rounded)

    // Body
    static let bodyLarge     = Font.system(size: 16, weight: .regular)
    static let bodyMedium    = Font.system(size: 15, weight: .regular)
    static let bodySmall     = Font.system(size: 13, weight: .regular)

    // Label
    static let labelLarge    = Font.system(size: 15, weight: .semibold)
    static let labelMedium   = Font.system(size: 13, weight: .semibold)
    static let labelSmall    = Font.system(size: 11, weight: .semibold)

    // Caption
    static let captionFont   = Font.system(size: 11, weight: .medium)
    static let captionCaps   = Font.system(size: 10, weight: .semibold)
}

// MARK: - Spacing Tokens

enum Spacing {
    static let xs:   CGFloat = 4
    static let sm:   CGFloat = 8
    static let md:   CGFloat = 12
    static let lg:   CGFloat = 16
    static let xl:   CGFloat = 20
    static let xxl:  CGFloat = 24
    static let xxxl: CGFloat = 32
}

// MARK: - Radius Tokens

enum Radius {
    static let sm:   CGFloat = 8
    static let md:   CGFloat = 12
    static let lg:   CGFloat = 16
    static let xl:   CGFloat = 20
    static let pill: CGFloat = 100
}
