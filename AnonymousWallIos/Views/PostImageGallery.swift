//
//  PostImageGallery.swift
//  AnonymousWallIos
//
//  Reusable horizontal image gallery used by post and marketplace views.
//  NOTE: AsyncImage does not cache responses. If frequent re-downloads become
//  noticeable, consider replacing with SDWebImageSwiftUI or Kingfisher which
//  provide in-memory and disk caching out of the box.
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
                    AsyncImage(url: URL(string: imageUrls[index])) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(
                                    width: imageUrls.count == 1 ? 300 : 200,
                                    height: 200
                                )
                                .clipped()
                                .cornerRadius(8)
                                .onTapGesture {
                                    selectedImageViewer = ImageViewerItem(index: index)
                                }
                                .accessibilityLabel("Image \(index + 1) of \(imageUrls.count)")
                                .accessibilityHint("Double tap to view full screen")
                        case .failure:
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.gray.opacity(0.2))
                                .frame(width: 200, height: 200)
                                .overlay(
                                    Image(systemName: "photo")
                                        .foregroundStyle(.gray)
                                )
                                .accessibilityLabel("Image failed to load")
                        case .empty:
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.gray.opacity(0.1))
                                .frame(width: 200, height: 200)
                                .overlay(ProgressView())
                        @unknown default:
                            EmptyView()
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
        .accessibilityLabel("\(accessibilityContext), \(imageUrls.count) photo\(imageUrls.count == 1 ? "" : "s")")
    }
}
