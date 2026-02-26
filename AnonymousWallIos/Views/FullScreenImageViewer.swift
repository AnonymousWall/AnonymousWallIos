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

    @State private var dismissDragOffset: CGFloat = 0
    @State private var isDismissing: Bool = false
    /// Stored reference so we can cancel the dismiss task if the view disappears first.
    @State private var dismissTask: Task<Void, Never>?

    private let minScale: CGFloat = 1.0
    private let maxScale: CGFloat = 5.0
    /// Vertical translation threshold beyond which a downward drag commits a dismiss.
    private let dismissThreshold: CGFloat = 120
    /// Duration (seconds) of the slide-out animation; also used as the Task sleep before calling dismiss().
    private let dismissAnimationDuration: TimeInterval = 0.2

    init(imageURLs: [String], initialIndex: Int = 0) {
        self.imageURLs = imageURLs
        self.initialIndex = initialIndex
        self._currentIndex = State(initialValue: initialIndex)
    }

    // Background opacity that dims as the user drags down
    private var backgroundOpacity: Double {
        let progress = abs(dismissDragOffset) / dismissThreshold
        return max(0, 1.0 - Double(progress) * 0.6)
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .top) {
                Color.black
                    .opacity(backgroundOpacity)
                    .ignoresSafeArea()
                    .animation(.easeOut(duration: 0.15), value: backgroundOpacity)

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
                                    // Only attach the pan gesture when zoomed in; at minScale the
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
                // Translate the entire paged view down while the user is swiping to dismiss
                .offset(y: dismissDragOffset)
                // Swipe-down-to-dismiss gesture (only active when not zoomed in)
                .gesture(
                    scale <= minScale ?
                    DragGesture(minimumDistance: 20, coordinateSpace: .local)
                        .onChanged { value in
                            // Only track downward drags
                            guard value.translation.height > 0 else { return }
                            dismissDragOffset = value.translation.height
                        }
                        .onEnded { value in
                            let shouldDismiss = value.translation.height > dismissThreshold
                                || value.predictedEndTranslation.height > dismissThreshold
                            if shouldDismiss {
                                isDismissing = true
                                withAnimation(.easeOut(duration: dismissAnimationDuration)) {
                                    dismissDragOffset = geometry.size.height
                                }
                                // Brief delay so the slide-out animation completes before dismiss.
                                // Task is stored so it can be cancelled if the view disappears first.
                                dismissTask = Task { @MainActor in
                                    try? await Task.sleep(nanoseconds: UInt64(dismissAnimationDuration * 1_000_000_000))
                                    guard !Task.isCancelled else { return }
                                    dismiss()
                                }
                            } else {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    dismissDragOffset = 0
                                }
                            }
                        }
                    : nil
                )
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
                .opacity(isDismissing ? 0 : 1)
            }
        }
        .onDisappear {
            dismissTask?.cancel()
        }
    }
}
