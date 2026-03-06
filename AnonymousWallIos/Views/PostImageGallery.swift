//
//  PostImageGallery.swift
//  AnonymousWallIos
//
//  Reusable horizontal image gallery used by post and marketplace views.
//  Uses AuthenticatedImageView to load images from the private OCI bucket
//  via the authenticated media proxy endpoint.
//

import SwiftUI

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

/// Single authenticated image cell with proper loading, failure, and accessibility states.
private struct PostImageGalleryCell: View {
    let url: String
    let width: CGFloat
    let index: Int
    let total: Int
    let onTap: () -> Void

    var body: some View {
        AuthenticatedImageView(objectName: url, contentMode: .fill)
            .frame(width: width, height: 200)
            .clipped()
            .cornerRadius(8)
            .onTapGesture(perform: onTap)
            .accessibilityLabel("Image \(index + 1) of \(total)")
            .accessibilityHint("Double tap to view full screen")
    }
}
