//
//  ConnectionStatusBarView.swift
//  AnonymousWallIos
//

import SwiftUI

struct ConnectionStatusBarView: View {
    let text: String
    let color: Color
    var showSpinner: Bool = true

    var body: some View {
        HStack {
            if showSpinner {
                    ProgressView().tint(.white).scaleEffect(0.7)
                }
            Text(text)
                .font(.caption)
                .foregroundColor(.white)
        }
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background(color)
    }
}
