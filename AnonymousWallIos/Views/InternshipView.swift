//
//  InternshipView.swift
//  AnonymousWallIos
//
//  Placeholder view for Internship tab
//

import SwiftUI

struct InternshipView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "briefcase.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                
                Text("Internship")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Coming Soon")
                    .font(.title2)
                    .foregroundColor(.gray)
                
                Text("Find and share internship opportunities")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .navigationTitle("Internship")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    InternshipView()
}
