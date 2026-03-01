//
//  SectionLabel.swift
//  AnonymousWallIos
//
//  Small-caps section header label.
//

import SwiftUI

struct SectionLabel: View {
    let text: String

    var body: some View {
        Text(text.uppercased())
            .font(.captionCaps)
            .foregroundColor(.textSecondary)
            .kerning(0.8)
            .accessibilityAddTraits(.isHeader)
    }
}

#Preview {
    SectionLabel(text: "Comments")
        .padding()
        .background(Color.appBackground)
}
