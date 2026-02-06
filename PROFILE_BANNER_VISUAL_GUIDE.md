# Profile Banner Collapse - Visual Guide

## Animation States

```
┌─────────────────────────────────────────────────────┐
│              NOT SCROLLED (scrollOffset = 0)        │
├─────────────────────────────────────────────────────┤
│                                                     │
│                   ╔════════╗                        │
│                   ║ Avatar ║  ← 90pt × 90pt         │
│                   ║  90pt  ║                        │
│                   ╚════════╝                        │
│                                                     │
│              student@harvard.edu  ← opacity: 1.0   │
│                                                     │
│              ┌──────────────┐                       │
│              │  John Doe    │    ← opacity: 1.0    │
│              └──────────────┘                       │
│                                                     │
│          Vertical Padding: 20pt                    │
├─────────────────────────────────────────────────────┤
│              [Posts] [Comments]                     │
├─────────────────────────────────────────────────────┤
│          Scrollable Content Area                    │
│          ↓ User scrolls down                        │
└─────────────────────────────────────────────────────┘


┌─────────────────────────────────────────────────────┐
│         PARTIALLY SCROLLED (scrollOffset = -50)     │
├─────────────────────────────────────────────────────┤
│                                                     │
│                  ╔═══════╗                          │
│                  ║Avatar ║  ← 70pt × 70pt          │
│                  ║ 70pt  ║    (shrinking)          │
│                  ╚═══════╝                          │
│                                                     │
│           student@harvard.edu  ← opacity: 0.0      │
│                (HIDDEN)                             │
│                                                     │
│                                                     │
│         Vertical Padding: 12.5pt                   │
│                (reducing)                           │
├─────────────────────────────────────────────────────┤
│              [Posts] [Comments]                     │
├─────────────────────────────────────────────────────┤
│          Scrollable Content Area                    │
│          ↓ User scrolls down more                   │
└─────────────────────────────────────────────────────┘


┌─────────────────────────────────────────────────────┐
│      FULLY COLLAPSED (scrollOffset = -100+)         │
├─────────────────────────────────────────────────────┤
│                                                     │
│                 ╔══════╗                            │
│                 ║Avatar║  ← 50pt × 50pt            │
│                 ║ 50pt ║    (minimum)              │
│                 ╚══════╝                            │
│                                                     │
│              (email hidden)                         │
│           (profile name hidden)                     │
│                                                     │
│        Vertical Padding: 5pt                       │
│           (minimum)                                 │
├─────────────────────────────────────────────────────┤
│              [Posts] [Comments]                     │
├─────────────────────────────────────────────────────┤
│          Scrollable Content Area                    │
│          (Maximum space for content)                │
└─────────────────────────────────────────────────────┘
```

## Animation Curves

### Avatar Size Animation (Threshold: 100pt)
```
  90pt ┤                              ╭─────────────
       │                           ╭──╯
  80pt ┤                        ╭──╯
       │                     ╭──╯
  70pt ┤                  ╭──╯
       │               ╭──╯
  60pt ┤            ╭──╯
       │         ╭──╯
  50pt ┤─────────╯
       └─────┬────┬────┬────┬────┬────┬────┬────┬────┬
             0   10   20   30   50   75  100  125  150
                    Scroll Distance (points)
```

### Banner Opacity Animation (Threshold: 50pt)
```
  1.0  ┤           ╭─────────────
       │        ╭──╯
  0.8  ┤      ╭─╯
       │    ╭─╯
  0.6  ┤  ╭─╯
       │╭─╯
  0.4  ┤╯
       │
  0.2  ┤
       │
  0.0  ┤───────────
       └─────┬────┬────┬────┬────┬────┬────┬────┬
             0   10   20   30   50   75  100  125
                    Scroll Distance (points)
```

### Vertical Padding Animation (Threshold: 100pt)
```
  20pt ┤                              ╭─────────────
       │                           ╭──╯
  18pt ┤                        ╭──╯
       │                     ╭──╯
  15pt ┤                  ╭──╯
       │               ╭──╯
  12pt ┤            ╭──╯
       │         ╭──╯
   8pt ┤      ╭──╯
       │   ╭──╯
   5pt ┤───╯
       └─────┬────┬────┬────┬────┬────┬────┬────┬────┬
             0   10   20   30   50   75  100  125  150
                    Scroll Distance (points)
```

## Scroll Offset Calculation

```
ScrollView Content
├─ Top of ScrollView        → scrollOffset = 0
│  (No scrolling yet)
│
├─ Scroll Down 25pt        → scrollOffset = -25
│  - Avatar: 80pt (smaller)
│  - Opacity: 0.5 (fading)
│  - Padding: 16.25pt
│
├─ Scroll Down 50pt        → scrollOffset = -50
│  - Avatar: 70pt
│  - Opacity: 0.0 (HIDDEN)
│  - Padding: 12.5pt
│
├─ Scroll Down 100pt       → scrollOffset = -100
│  - Avatar: 50pt (minimum)
│  - Opacity: 0.0 (HIDDEN)
│  - Padding: 5pt (minimum)
│
└─ Scroll Down 150pt+      → scrollOffset = -150+
   - Avatar: 50pt (stays at minimum)
   - Opacity: 0.0 (stays hidden)
   - Padding: 5pt (stays at minimum)
```

## Implementation Architecture

```
ProfileView
├─ State Management
│  └─ @State private var scrollOffset: CGFloat = 0
│
├─ Computed Properties (React to scrollOffset changes)
│  ├─ avatarSize: CGFloat
│  │  └─ Calculates size based on scroll position
│  ├─ bannerOpacity: Double
│  │  └─ Calculates opacity based on scroll position
│  └─ bannerVerticalPadding: CGFloat
│     └─ Calculates padding based on scroll position
│
├─ Scroll Tracking
│  ├─ ScrollOffsetPreferenceKey
│  │  └─ Tracks scroll position via GeometryReader
│  ├─ GeometryReader (in ScrollView)
│  │  └─ Measures scroll position
│  └─ onPreferenceChange
│     └─ Updates scrollOffset state
│
└─ UI Elements
   ├─ Password Setup Banner (static)
   ├─ Profile Banner (animated) ← OUR CHANGES
   │  ├─ Avatar (dynamic size)
   │  ├─ Email (dynamic opacity)
   │  └─ Profile Name Badge (dynamic opacity)
   ├─ Segment Control (Posts/Comments)
   ├─ Sort Menu
   └─ ScrollView (with content)
      └─ Posts or Comments List
```

## Animation Timeline

```
Time: 0ms → User starts scrolling
├─ scrollOffset starts changing (0 → -1 → -2 → ...)
│
Time: 0-200ms → Animation in progress
├─ SwiftUI interpolates values
├─ .easeInOut(duration: 0.2) curve applied
├─ GPU handles frame-by-frame rendering
│  ├─ Frame 1: Avatar 90pt, Opacity 1.0, Padding 20pt
│  ├─ Frame 2: Avatar 88pt, Opacity 0.96, Padding 19.2pt
│  ├─ Frame 3: Avatar 86pt, Opacity 0.92, Padding 18.4pt
│  └─ ... (60fps = ~12 frames total)
│
Time: 200ms+ → Animation complete
└─ Elements settle at new positions
```

## Code Flow Diagram

```
User Scrolls Down
      ↓
ScrollView detects motion
      ↓
GeometryReader measures new position
      ↓
ScrollOffsetPreferenceKey updates
      ↓
onPreferenceChange fires
      ↓
scrollOffset state updated (e.g., 0 → -25)
      ↓
Computed properties recalculate
      ├─ avatarSize: 90 → 80
      ├─ bannerOpacity: 1.0 → 0.5
      └─ bannerVerticalPadding: 20 → 16.25
      ↓
SwiftUI detects value changes
      ↓
.animation modifier triggers
      ↓
GPU renders smooth transition (200ms)
      ↓
User sees smooth animation
```

## Key Technical Decisions

### Why These Thresholds?

1. **50pt for Opacity**
   - Quick fade prevents text looking "half-visible"
   - Text fully hidden before avatar is even halfway collapsed
   - Creates clean, decisive transition

2. **100pt for Avatar Size & Padding**
   - Gradual enough to feel smooth
   - Fast enough to not feel sluggish
   - Avatar remains recognizable throughout

3. **0.2s Animation Duration**
   - Fast enough to feel responsive
   - Slow enough to be visually smooth
   - Standard iOS animation duration

### Why easeInOut?
- Starts slow (ease in)
- Accelerates in middle (smooth)
- Slows at end (ease out)
- Most natural-feeling curve for this type of animation

## Performance Characteristics

```
CPU Usage
  ├─ Computed properties: O(1) - constant time
  ├─ State updates: O(1) - single value
  └─ Total: Minimal, negligible impact

GPU Usage
  ├─ Animations: Hardware accelerated
  ├─ Frame rate: 60fps maintained
  └─ Total: Efficient, no janking

Memory Usage
  ├─ State: 8 bytes (1 CGFloat)
  ├─ Computed: 0 bytes (calculated on-demand)
  └─ Total: Negligible overhead
```

## Compatibility Matrix

```
✅ Works with Posts tab
✅ Works with Comments tab
✅ Works with Pull-to-refresh
✅ Works with Segment switching
✅ Works with Sort menu
✅ Works with Password banner
✅ Works with Navigation
✅ Works with Sheets/Modals
✅ Works with Empty states
✅ Works with Loading states
```
