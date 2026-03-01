//
//  PostImageGallery.swift
//  AnonymousWallIos
//
//  Reusable horizontal image gallery used by post and marketplace views.
//  Uses Kingfisher (KFImage) for in-memory and disk caching to reduce
//  redundant network requests and lower memory pressure.
//

import SwiftUI
import Kingfisher

struct PostImageGallery: View {
    let imageUrls: [String]
    @Binding var selectedImageViewer: ImageViewerItem?
    var accessibilityContext: String = "Images"

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(imageUrls.indices, id: \.self) { index in
                    PostImageGalleryCell(
                        url: imageUrls[index],
                        width: imageUrls.count == 1 ? 300 : 200,
                        index: index,
                        total: imageUrls.count
                    ) {
                        selectedImageViewer = ImageViewerItem(index: index)
                    }
                }
            }
            .padding(.horizontal)
        }
        .accessibilityLabel("\(accessibilityContext), \(imageUrls.count) photo\(imageUrls.count == 1 ? "" : "s")")
    }
}

/// Single cached image cell with proper loading, failure, and accessibility states.
private struct PostImageGalleryCell: View {
    let url: String
    let width: CGFloat
    let index: Int
    let total: Int
    let onTap: () -> Void

    @State private var loadFailed = false

    var body: some View {
        if loadFailed {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.2))
                .frame(width: width, height: 200)
                .overlay(
                    Image(systemName: "photo")
                        .foregroundStyle(.gray)
                )
                .accessibilityLabel("Image failed to load")
        } else {
            KFImage(URL(string: url))
                .placeholder {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.1))
                        .frame(width: width, height: 200)
                        .overlay(ProgressView())
                }
                .onFailure { _ in loadFailed = true }
                .resizable()
                .scaledToFill()
                .frame(width: width, height: 200)
                .clipped()
                .cornerRadius(8)
                .onTapGesture(perform: onTap)
                .accessibilityLabel("Image \(index + 1) of \(total)")
                .accessibilityHint("Double tap to view full screen")
        }
    }
}
