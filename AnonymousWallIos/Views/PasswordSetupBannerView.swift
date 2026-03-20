//
//  PasswordSetupBannerView.swift
//  AnonymousWallIos
//
//  Reusable alert banner shown when the user needs to set a password.
//

import SwiftUI

struct PasswordSetupBannerView: View {
    let onTap: () -> Void

    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.accentOrange)
                .accessibilityHidden(true)
            Text("Please set up your password to secure your account")
                .font(.captionMedium)
                .foregroundColor(.textPrimary)
            Spacer()
            Button("Set Now", action: onTap)
                .font(.captionMedium)
                .fontWeight(.semibold)
                .foregroundColor(.accentPurple)
        }
        .padding()
        .background(Color.accentOrange.opacity(Opacity.light))
        .cornerRadius(Radius.sm)
        .padding()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Security alert: Please set up your password to secure your account. Tap Set Now to proceed.")
        .accessibilityAddTraits(.isButton)
    }
}
