//
//  FullScreenImageViewer.swift
//  AnonymousWallIos
//
//  Full-screen image viewer with swipe-to-page, pinch-to-zoom and dismiss support
//

import SwiftUI
import Kingfisher

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

    // Zoom
    @State private var scale: CGFloat = 1.0
    @GestureState private var pinchDelta: CGFloat = 1.0   // live pinch multiplier, resets on end

    // Pan while zoomed — GestureState gives smooth real-time updates without full re-renders
    @State private var panOffset: CGSize = .zero
    @GestureState private var livePanDelta: CGSize = .zero // live delta on top of panOffset

    // Dismiss drag
    @State private var dismissOffset: CGFloat = 0
    @GestureState private var liveDismissDelta: CGFloat = 0
    @State private var isDismissing: Bool = false
    @State private var dismissTask: Task<Void, Never>?

    // Chrome
    @State private var showChrome: Bool = true

    private let minScale: CGFloat = 1.0
    private let maxScale: CGFloat = 5.0
    private let dismissThreshold: CGFloat = 120
    private let dismissAnimationDuration: TimeInterval = 0.25
    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)

    init(imageURLs: [String], initialIndex: Int = 0) {
        self.imageURLs = imageURLs
        self.initialIndex = initialIndex
        self._currentIndex = State(initialValue: initialIndex)
    }

    // Combine committed pan + live gesture delta, clamped to image bounds
    private func currentOffset(in size: CGSize) -> CGSize {
        let combined = CGSize(
            width: panOffset.width + livePanDelta.width,
            height: panOffset.height + livePanDelta.height
        )
        return clamp(combined, scale: liveScale, in: size)
    }

    // Combine committed scale + live pinch delta
    private var liveScale: CGFloat {
        min(max(scale * pinchDelta, minScale), maxScale)
    }

    private var backgroundOpacity: Double {
        let drag = abs(dismissOffset) + abs(liveDismissDelta)
        return max(0, 1.0 - Double(drag / dismissThreshold))
    }

    private var dismissDragOffset: CGFloat {
        dismissOffset + liveDismissDelta
    }

    private var dismissDragScale: CGFloat {
        let progress = min(abs(dismissDragOffset) / dismissThreshold, 1.0)
        return 1.0 - progress * 0.15
    }

    private func clamp(_ offset: CGSize, scale: CGFloat, in size: CGSize) -> CGSize {
        let maxX = max(0, (scale - 1) * size.width / 2)
        let maxY = max(0, (scale - 1) * size.height / 2)
        return CGSize(
            width: max(-maxX, min(maxX, offset.width)),
            height: max(-maxY, min(maxY, offset.height))
        )
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .top) {

                Color.black
                    .opacity(backgroundOpacity)
                    .ignoresSafeArea()

                // TabView handles ALL left/right page transitions natively.
                // We never programmatically set currentIndex for page turns —
                // that fights TabView's animation and causes jumps.
                TabView(selection: $currentIndex) {
                    ForEach(imageURLs.indices, id: \.self) { index in
                        imageCell(for: index, geometry: geometry)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .scaleEffect(dismissDragScale)
                .offset(y: dismissDragOffset)
                .simultaneousGesture(scale <= minScale ? dismissGesture() : nil)
                .onChange(of: currentIndex) { _, _ in
                    scale = minScale
                    panOffset = .zero
                    feedbackGenerator.impactOccurred()
                }

                // Chrome
                let showingChrome = showChrome && scale <= minScale && !isDismissing
                VStack {
                    HStack {
                        if imageURLs.count > 1 {
                            Text("\(currentIndex + 1) / \(imageURLs.count)")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(.black.opacity(0.45), in: Capsule())
                                .padding(.leading, 16)
                        }
                        Spacer()
                        Button { dismiss() } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(width: 36, height: 36)
                                .background(.black.opacity(0.45), in: Circle())
                                .padding(16)
                        }
                        .accessibilityLabel("Close")
                    }
                    Spacer()
                }
                .opacity(showingChrome ? 1 : 0)
                .animation(.easeInOut(duration: 0.2), value: showingChrome)
            }
        }
        .onAppear { feedbackGenerator.prepare() }
        .onDisappear { dismissTask?.cancel() }
    }

    // MARK: - Image Cell

    @ViewBuilder
    private func imageCell(for index: Int, geometry: GeometryProxy) -> some View {
        KFImage(URL(string: imageURLs[index]))
            .placeholder {
                ProgressView().tint(.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .resizable()
            .scaledToFit()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .scaleEffect(index == currentIndex ? liveScale : 1.0)
            .offset(index == currentIndex ? currentOffset(in: geometry.size) : .zero)
            .gesture(liveScale > minScale ? panGesture(in: geometry.size) : nil)
            .gesture(pinchGesture())
            .onTapGesture(count: 2) {
                guard !voiceOverEnabled else { return }
                withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                    if scale > minScale {
                        scale = minScale
                        panOffset = .zero
                    } else {
                        scale = 2.5
                    }
                }
            }
            .onTapGesture(count: 1) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showChrome.toggle()
                }
            }
            .accessibilityLabel("Image \(index + 1) of \(imageURLs.count)")
    }

    // MARK: - Pan Gesture
    //
    // @GestureState (livePanDelta) tracks finger position in real time.
    // SwiftUI updates the gesture layer directly — no full view re-render
    // on every event. panOffset (@State) is only written on gesture end.

    private func panGesture(in size: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 8)
            .updating($livePanDelta) { value, state, _ in
                state = value.translation
            }
            .onEnded { value in
                let newOffset = CGSize(
                    width: panOffset.width + value.translation.width,
                    height: panOffset.height + value.translation.height
                )
                let clampedOffset = clamp(newOffset, scale: scale, in: size)
                panOffset = clampedOffset

                // When pan hits the horizontal edge, treat a continued
                // over-swipe as a page-turn. Set currentIndex directly
                // (no withAnimation) so TabView animates the transition natively.
                let edgeBuffer: CGFloat = 20
                let maxX = max(0, (scale - 1) * size.width / 2)
                let rawEndX = panOffset.width + value.translation.width
                let predictedEndX = panOffset.width + value.predictedEndTranslation.width

                if rawEndX < -(maxX + edgeBuffer),
                   predictedEndX < -(maxX + edgeBuffer),
                   currentIndex < imageURLs.count - 1 {
                    currentIndex += 1
                } else if rawEndX > (maxX + edgeBuffer),
                          predictedEndX > (maxX + edgeBuffer),
                          currentIndex > 0 {
                    currentIndex -= 1
                }
            }
    }

    // MARK: - Pinch Gesture
    //
    // @GestureState (pinchDelta) for live feedback.
    // scale (@State) committed on end with a spring animation.

    private func pinchGesture() -> some Gesture {
        MagnificationGesture()
            .updating($pinchDelta) { value, state, _ in
                state = value
            }
            .onEnded { value in
                let newScale = min(max(scale * value, minScale), maxScale)
                withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                    scale = newScale
                    if newScale <= minScale {
                        panOffset = .zero
                    }
                }
            }
    }

    // MARK: - Dismiss Gesture
    //
    // @GestureState (liveDismissDelta) for smooth image-follows-finger feel.
    // Automatically springs back to zero if the gesture doesn't cross the
    // dismiss threshold — no manual reset needed.

    private func dismissGesture() -> some Gesture {
        DragGesture(minimumDistance: 20, coordinateSpace: .local)
            .updating($liveDismissDelta) { value, state, _ in
                let h = value.translation.height
                let w = value.translation.width
                guard h > 0, abs(h) > abs(w) * 2 else { return }
                state = h
            }
            .onEnded { value in
                let h = value.translation.height
                let w = value.translation.width
                let isDownward = h > 0 && abs(h) > abs(w) * 2
                let shouldDismiss = isDownward && (
                    h > dismissThreshold || value.predictedEndTranslation.height > dismissThreshold
                )
                if shouldDismiss {
                    isDismissing = true
                    withAnimation(.easeOut(duration: dismissAnimationDuration)) {
                        dismissOffset = 1000
                    }
                    dismissTask = Task { @MainActor in
                        try? await Task.sleep(nanoseconds: UInt64(dismissAnimationDuration * 1_000_000_000))
                        guard !Task.isCancelled else { return }
                        dismiss()
                    }
                }
            }
    }
}
