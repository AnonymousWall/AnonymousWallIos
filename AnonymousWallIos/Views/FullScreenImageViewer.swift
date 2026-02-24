//
//  FullScreenImageViewer.swift
//  AnonymousWallIos
//
//  Full-screen image viewer with pinch-to-zoom and dismiss support
//

import SwiftUI

/// Identifiable wrapper for a URL string, used to drive fullScreenCover(item:)
struct ImageURLItem: Identifiable {
    let id = UUID()
    let url: String
}

struct FullScreenImageViewer: View {
    let imageURL: String
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOverEnabled

    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    private let minScale: CGFloat = 1.0
    private let maxScale: CGFloat = 5.0

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black.ignoresSafeArea()

            // NOTE: AsyncImage does not cache responses. If frequent re-downloads become
            // noticeable, consider replacing with SDWebImageSwiftUI or Kingfisher which
            // provide in-memory and disk caching out of the box.
            AsyncImage(url: URL(string: imageURL)) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFit()
                        .scaleEffect(scale)
                        .offset(offset)
                        .gesture(
                            MagnificationGesture()
                                .onChanged { value in
                                    let delta = value / lastScale
                                    lastScale = value
                                    scale = min(max(scale * delta, minScale), maxScale)
                                }
                                .onEnded { _ in
                                    lastScale = 1.0
                                    if scale < minScale {
                                        withAnimation { scale = minScale; offset = .zero; lastOffset = .zero }
                                    }
                                }
                                .simultaneously(with:
                                    DragGesture()
                                        .onChanged { value in
                                            offset = CGSize(
                                                width: lastOffset.width + value.translation.width,
                                                height: lastOffset.height + value.translation.height
                                            )
                                        }
                                        .onEnded { _ in
                                            lastOffset = offset
                                            if scale <= minScale {
                                                withAnimation { offset = .zero; lastOffset = .zero }
                                            }
                                        }
                                )
                        )
                        .onTapGesture(count: 2) {
                            guard !voiceOverEnabled else { return }
                            withAnimation {
                                if scale > minScale {
                                    scale = minScale
                                    offset = .zero
                                    lastOffset = .zero
                                } else {
                                    scale = 2.5
                                }
                            }
                        }
                        .accessibilityLabel("Full screen image")
                case .failure:
                    Image(systemName: "photo")
                        .font(.largeTitle)
                        .foregroundStyle(.gray)
                        .accessibilityLabel("Image failed to load")
                case .empty:
                    ProgressView()
                        .tint(.white)
                @unknown default:
                    EmptyView()
                }
            }

            // Close button
            Button(action: { dismiss() }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title)
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.white, Color.black.opacity(0.6))
                    .padding(16)
            }
            .accessibilityLabel("Close")
            .accessibilityHint("Double tap to close the full screen image")
        }
    }
}
