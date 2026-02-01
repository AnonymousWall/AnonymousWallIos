//
//  MarketView.swift
//  AnonymousWallIos
//
//  Placeholder view for Market tab
//

import SwiftUI

struct MarketView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "cart.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.green)
                
                Text("Market")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Coming Soon")
                    .font(.title2)
                    .foregroundColor(.gray)
                
                Text("Buy and sell items with other students")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .navigationTitle("Market")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    MarketView()
}
