//
//  DesignSystem.swift
//  AnonymousWallIos
//
//  Central design token definitions: colours, typography, spacing, and radii.
//

import SwiftUI
import UIKit

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

    // Adaptive background: dark mode #0d0d0f / light mode #f5f5f7
    static let appBackground = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 13/255, green: 13/255, blue: 15/255, alpha: 1)
            : UIColor(red: 245/255, green: 245/255, blue: 247/255, alpha: 1)
    })

    // Adaptive surface: dark mode #17171a / light mode white
    static let surfacePrimary = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 23/255, green: 23/255, blue: 26/255, alpha: 1)
            : UIColor.white
    })

    // Adaptive surface: dark mode #1f1f23 / light mode #f2f2f5
    static let surfaceSecondary = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 31/255, green: 31/255, blue: 35/255, alpha: 1)
            : UIColor(red: 242/255, green: 242/255, blue: 245/255, alpha: 1)
    })

    // Adaptive surface: dark mode #26262b / light mode #e8e8ed
    static let surfaceTertiary = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 38/255, green: 38/255, blue: 43/255, alpha: 1)
            : UIColor(red: 232/255, green: 232/255, blue: 237/255, alpha: 1)
    })

    // Adaptive border: dark mode white opacity / light mode black opacity
    static let borderSubtle = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor.white.withAlphaComponent(0.07)
            : UIColor.black.withAlphaComponent(0.08)
    })

    static let borderMedium = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor.white.withAlphaComponent(0.12)
            : UIColor.black.withAlphaComponent(0.15)
    })

    // Adaptive text: dark mode #f2f2f5 / light mode #0d0d0f
    static let textPrimary = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 242/255, green: 242/255, blue: 245/255, alpha: 1)
            : UIColor(red: 13/255, green: 13/255, blue: 15/255, alpha: 1)
    })

    // Adaptive text: dark mode #8a8a96 / light mode #55555e
    static let textSecondary = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 138/255, green: 138/255, blue: 150/255, alpha: 1)
            : UIColor(red: 85/255, green: 85/255, blue: 94/255, alpha: 1)
    })

    // Adaptive text: dark mode #55555e / light mode #8a8a96
    static let textTertiary = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 85/255, green: 85/255, blue: 94/255, alpha: 1)
            : UIColor(red: 138/255, green: 138/255, blue: 150/255, alpha: 1)
    })

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
