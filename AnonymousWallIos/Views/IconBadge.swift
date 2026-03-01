//
//  IconBadge.swift
//  AnonymousWallIos
//
//  Coloured icon container — used in sheets, settings rows, and type pickers.
//

import SwiftUI

struct IconBadge: View {
    let systemName: String
    let color: Color
    var size: CGFloat = 44

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: Radius.md)
                .fill(color.opacity(0.12))
                .frame(width: size, height: size)
            Image(systemName: systemName)
                .font(.system(size: size * 0.4, weight: .semibold))
                .foregroundColor(color)
        }
        .accessibilityHidden(true)
    }
}

#Preview {
    HStack(spacing: 16) {
        IconBadge(systemName: "house.fill", color: .accentPurple)
        IconBadge(systemName: "star.fill", color: .accentOrange)
        IconBadge(systemName: "trash.fill", color: .accentRed)
    }
    .padding()
    .background(Color.appBackground)
}
