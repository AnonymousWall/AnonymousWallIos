//
//  BadgeView.swift
//  AnonymousWallIos
//
//  Numeric count badge — compact pill showing an integer count on an accentRed background.
//  Use for unread message counts, notification dots, and similar numeric indicators.
//  For text pill labels use ChipBadge. For icon containers use IconBadge.
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
