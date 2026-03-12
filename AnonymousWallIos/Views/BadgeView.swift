//
//  BadgeView.swift
//  AnonymousWallIos
//

import SwiftUI

struct BadgeView: View {
    let count: Int

    var body: some View {
        Text("\(count)")
            .font(.caption2.bold())
            .foregroundColor(.white)
            .padding(.horizontal, count > 9 ? 6 : 8)
            .padding(.vertical, 4)
            .background(Color.accentRed)
            .cornerRadius(10)
    }
}
