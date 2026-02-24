//
//  FullScreenImageViewer.swift
//  AnonymousWallIos
//
//  Full-screen image viewer with swipe-to-page, pinch-to-zoom and dismiss support
//

import SwiftUI

/// Identifiable wrapper used to present FullScreenImageViewer via fullScreenCover(item:)
struct ImageViewerItem: Identifiable {
    let id = UUID()
    let index: Int
}

struct FullScreenImageViewer: View {
    let imageURLs: [String]
    let initialIndex: Int
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOverEnabled

    @State private var currentIndex: Int
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    private let minScale: CGFloat = 1.0
    private let maxScale: CGFloat = 5.0

    init(imageURLs: [String], initialIndex: Int = 0) {
        self.imageURLs = imageURLs
        self.initialIndex = initialIndex
        self._currentIndex = State(initialValue: initialIndex)
    }

    var body: some View {
        ZStack(alignment: .top) {
            Color.black.ignoresSafeArea()

            // NOTE: AsyncImage does not cache responses. If frequent re-downloads become
            // noticeable, consider replacing with SDWebImageSwiftUI or Kingfisher which
            // provide in-memory and disk caching out of the box.
            TabView(selection: $currentIndex) {
                ForEach(imageURLs.indices, id: \.self) { index in
                    AsyncImage(url: URL(string: imageURLs[index])) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .scaleEffect(index == currentIndex ? scale : 1.0)
                                .offset(index == currentIndex ? offset : .zero)
                                // Only attach the drag gesture when zoomed in; at minScale the
                                // TabView's native page-swipe gesture should have priority.
                                .gesture(scale > minScale ?
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
                                                withAnimation {
                                                    offset = .zero
                                                    lastOffset = .zero
                                                }
                                            }
                                        }
                                    : nil
                                )
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
                                                withAnimation {
                                                    scale = minScale
                                                    offset = .zero
                                                    lastOffset = .zero
                                                }
                                            }
                                        }
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
                                .accessibilityLabel("Image \(index + 1) of \(imageURLs.count)")
                        case .failure:
                            Image(systemName: "photo")
                                .font(.largeTitle)
                                .foregroundStyle(.gray)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .accessibilityLabel("Image failed to load")
                        case .empty:
                            ProgressView()
                                .tint(.white)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        @unknown default:
                            EmptyView()
                        }
                    }
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .onChange(of: currentIndex) { _, _ in
                // Reset zoom and pan when swiping to a new image
                scale = minScale
                offset = .zero
                lastOffset = .zero
            }

            // Close button
            HStack {
                Spacer()
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
}
