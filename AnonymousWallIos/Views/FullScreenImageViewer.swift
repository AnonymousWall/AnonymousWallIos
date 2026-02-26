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
    /// How far past the horizontal edge (in points) the user must over-swipe before the drag
    /// is treated as a page-turn intent rather than a regular pan.
    private let pageTurnEdgeBuffer: CGFloat = 20

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

    /// Maximum pan translation (per axis) before the image would move off-screen at the given scale.
    private func maxPanOffset(for scale: CGFloat, in viewSize: CGSize) -> CGSize {
        CGSize(
            width: max(0, (scale - 1) * viewSize.width / 2),
            height: max(0, (scale - 1) * viewSize.height / 2)
        )
    }

    /// Clamps `offset` so the image stays within the visible area at `scale`.
    private func clampedOffset(_ offset: CGSize, scale: CGFloat, in viewSize: CGSize) -> CGSize {
        let limit = maxPanOffset(for: scale, in: viewSize)
        return CGSize(
            width: max(-limit.width, min(limit.width, offset.width)),
            height: max(-limit.height, min(limit.height, offset.height))
        )
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
                                                let raw = CGSize(
                                                    width: lastOffset.width + value.translation.width,
                                                    height: lastOffset.height + value.translation.height
                                                )
                                                offset = clampedOffset(raw, scale: scale, in: geometry.size)
                                            }
                                            .onEnded { value in
                                                let startOffset = lastOffset
                                                lastOffset = offset
                                                if scale <= minScale {
                                                    withAnimation {
                                                        offset = .zero
                                                        lastOffset = .zero
                                                    }
                                                } else {
                                                    // When panning hits a horizontal edge, treat a continued
                                                    // over-swipe as a page-turn gesture. The raw (unclamped)
                                                    // end position and predicted end must both exceed the edge
                                                    // limit by a small buffer to avoid accidental triggers.
                                                    let limit = maxPanOffset(for: scale, in: geometry.size)
                                                    let rawEndX = startOffset.width + value.translation.width
                                                    let predictedEndX = startOffset.width + value.predictedEndTranslation.width
                                                    if rawEndX < -(limit.width + pageTurnEdgeBuffer),
                                                       predictedEndX < -(limit.width + pageTurnEdgeBuffer),
                                                       currentIndex < imageURLs.count - 1 {
                                                        withAnimation {
                                                            currentIndex += 1
                                                            scale = minScale
                                                            offset = .zero
                                                            lastOffset = .zero
                                                        }
                                                    } else if rawEndX > (limit.width + pageTurnEdgeBuffer),
                                                              predictedEndX > (limit.width + pageTurnEdgeBuffer),
                                                              currentIndex > 0 {
                                                        withAnimation {
                                                            currentIndex -= 1
                                                            scale = minScale
                                                            offset = .zero
                                                            lastOffset = .zero
                                                        }
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
                                                // Keep the pan within bounds as the scale changes.
                                                offset = clampedOffset(offset, scale: scale, in: geometry.size)
                                            }
                                            .onEnded { _ in
                                                lastScale = 1.0
                                                if scale <= minScale {
                                                    // Pinched back to 1× — re-center completely.
                                                    withAnimation {
                                                        scale = minScale
                                                        offset = .zero
                                                        lastOffset = .zero
                                                    }
                                                } else {
                                                    // Partial zoom-out: clamp any residual out-of-bounds offset.
                                                    withAnimation {
                                                        offset = clampedOffset(offset, scale: scale, in: geometry.size)
                                                        lastOffset = offset
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
                // Use simultaneousGesture so this drag runs alongside the TabView's own
                // page-swipe gesture instead of competing with it. This is what makes the
                // image visually follow the finger on a downward drag.
                .simultaneousGesture(
                    scale <= minScale ?
                    DragGesture(minimumDistance: 20, coordinateSpace: .local)
                        .onChanged { value in
                            let h = value.translation.height
                            let w = value.translation.width
                            // Require a strongly downward gesture: vertical must be > 0 and at
                            // least 2× the horizontal component (~63° from horizontal). This
                            // prevents accidental dismissal during left/right page-turn swipes.
                            guard h > 0, abs(h) > abs(w) * 2 else {
                                // If the gesture turns out to be mostly horizontal, spring back
                                // any offset that may have been set before the direction was clear.
                                if dismissDragOffset != 0 {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        dismissDragOffset = 0
                                    }
                                }
                                return
                            }
                            dismissDragOffset = h
                        }
                        .onEnded { value in
                            let h = value.translation.height
                            let w = value.translation.width
                            // Apply the same directional guard on release so a fast diagonal
                            // swipe can never trigger a dismiss.
                            let isDownwardGesture = h > 0 && abs(h) > abs(w) * 2
                            let shouldDismiss = isDownwardGesture && (
                                h > dismissThreshold || value.predictedEndTranslation.height > dismissThreshold
                            )
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
