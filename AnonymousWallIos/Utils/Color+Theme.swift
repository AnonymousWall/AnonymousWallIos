//
//  Color+Theme.swift
//  AnonymousWallIos
//
//  Theme colors extension for college-friendly UI
//

import SwiftUI

extension Color {
    // Primary brand colors with fallback values for safety
    static let primaryPurple = Color("PrimaryPurple") 
    static let primaryPink = Color("PrimaryPink")
    static let vibrantOrange = Color("VibrantOrange")
    static let vibrantTeal = Color("VibrantTeal")
    static let softPurple = Color("SoftPurple")
    
    // Gradient combinations for modern look
    static var purplePinkGradient: LinearGradient {
        LinearGradient(
            colors: [primaryPurple, primaryPink],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    static var tealPurpleGradient: LinearGradient {
        LinearGradient(
            colors: [vibrantTeal, softPurple],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    static var orangePinkGradient: LinearGradient {
        LinearGradient(
            colors: [vibrantOrange, primaryPink],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
