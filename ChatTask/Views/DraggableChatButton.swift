import SwiftUI

// MARK: - Metrics

private enum DraggableChatButtonMetrics {
    static let size: CGFloat = 56
    static let edgeMargin: CGFloat = 16
    /// Small gap above the home indicator / bottom safe inset (8–16 pt range; keeps the
    /// circle fully visible without a large artificial “danger zone”).
    static let bottomSafeMargin: CGFloat = 12
    /// Movement at or below this distance (points) counts as a tap, not a drag.
    static let tapDistanceThreshold: CGFloat = 12
}

// MARK: - DraggableChatButton

/// A Messenger-style floating action button: draggable, edge-snapping, persisted, and
/// non-blocking (full-screen pass-through except on the circle).
struct DraggableChatButton: View {

    /// Persisted horizontal position: 0 = left edge of the safe band, 1 = right (default).
    @AppStorage("homeChatFABRelX") private var storedRelX: Double = 1.0
    /// Persisted vertical position: 0 = top of the safe band, 1 = bottom (default).
    @AppStorage("homeChatFABRelY") private var storedRelY: Double = 1.0

    let onTap: () -> Void
    let accessibilityLabel: String

    @State private var dragTranslation: CGSize = .zero
    @State private var isDragging = false
    #if DEBUG
    @State private var didLogInitialLayout = false
    #endif

    var body: some View {
        GeometryReader { geo in
            let layout = layoutMetrics(in: geo)
            if layout.isValid {
                let base = storedCenter(in: layout)
                let rawEnd = CGPoint(
                    x: base.x + dragTranslation.width,
                    y: base.y + dragTranslation.height
                )
                let clampedDrag = clampToSafeBand(rawEnd, layout: layout)
                let dragOffset = CGSize(
                    width: clampedDrag.x - base.x,
                    height: clampedDrag.y - base.y
                )

                ZStack {
                    Color.clear
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .allowsHitTesting(false)

                    Image(systemName: "message.fill")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: DraggableChatButtonMetrics.size, height: DraggableChatButtonMetrics.size)
                        .background(Color.accentColor)
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.2), radius: 6, y: 3)
                        .scaleEffect(isDragging ? 1.06 : 1.0)
                        .opacity(isDragging ? 0.92 : 1.0)
                        .animation(.easeInOut(duration: 0.18), value: isDragging)
                        .position(base)
                        .offset(dragOffset)
                        .contentShape(Circle())
                        .accessibilityLabel(accessibilityLabel)
                        .accessibilityAddTraits(.isButton)
                        .accessibilityAction { onTap() }
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    let d = hypot(value.translation.width, value.translation.height)
                                    if d > DraggableChatButtonMetrics.tapDistanceThreshold {
                                        isDragging = true
                                    }
                                    dragTranslation = value.translation
                                }
                                .onEnded { value in
                                    let total = hypot(value.translation.width, value.translation.height)
                                    let layoutNow = layoutMetrics(in: geo)
                                    defer {
                                        dragTranslation = .zero
                                        isDragging = false
                                    }
                                    guard layoutNow.isValid else { return }
                                    if total <= DraggableChatButtonMetrics.tapDistanceThreshold {
                                        onTap()
                                        return
                                    }
                                    let baseNow = storedCenter(in: layoutNow)
                                    let endRaw = CGPoint(
                                        x: baseNow.x + value.translation.width,
                                        y: baseNow.y + value.translation.height
                                    )
                                    let midX = (layoutNow.minCenterX + layoutNow.maxCenterX) / 2
                                    let snappedX = endRaw.x < midX ? layoutNow.minCenterX : layoutNow.maxCenterX
                                    let snappedY = min(max(endRaw.y, layoutNow.minCenterY), layoutNow.maxCenterY)
                                    let snapped = CGPoint(x: snappedX, y: snappedY)
                                    let denomX = max(layoutNow.maxCenterX - layoutNow.minCenterX, 1)
                                    let denomY = max(layoutNow.maxCenterY - layoutNow.minCenterY, 1)
                                    let nx = (snapped.x - layoutNow.minCenterX) / denomX
                                    let ny = (snapped.y - layoutNow.minCenterY) / denomY
                                    #if DEBUG
                                    logLayoutDebug(geo: geo, layout: layoutNow, phase: "drop", droppedCenterY: snapped.y)
                                    #endif
                                    withAnimation(.spring(response: 0.38, dampingFraction: 0.84)) {
                                        storedRelX = Double(nx)
                                        storedRelY = Double(ny)
                                    }
                                }
                        )
                }
                #if DEBUG
                .onAppear {
                    guard !didLogInitialLayout else { return }
                    didLogInitialLayout = true
                    logLayoutDebug(geo: geo, layout: layout, phase: "initial", droppedCenterY: nil)
                }
                #endif
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .allowsHitTesting(true)
    }

    #if DEBUG
    private func logLayoutDebug(geo: GeometryProxy, layout: SafeBand, phase: String, droppedCenterY: CGFloat?) {
        let half = DraggableChatButtonMetrics.size / 2
        let safe = geo.safeAreaInsets
        var message = """
        [DraggableChatButton] \(phase)
          container: \(geo.size.width) x \(geo.size.height)
          safeArea.top=\(safe.top) safeArea.bottom=\(safe.bottom) leading=\(safe.leading) trailing=\(safe.trailing)
          buttonSize=\(DraggableChatButtonMetrics.size)
          minCenterY=\(layout.minCenterY) maxCenterY=\(layout.maxCenterY)
          minButtonTopY=\(layout.minCenterY - half) maxButtonBottomY=\(layout.maxCenterY + half)
        """
        if let y = droppedCenterY {
            message += "\n  droppedCenterY=\(y) droppedButtonBottomY=\(y + half)"
        }
        print(message)
    }
    #endif

    // MARK: - Layout

    private struct SafeBand {
        let minCenterX: CGFloat
        let maxCenterX: CGFloat
        let minCenterY: CGFloat
        let maxCenterY: CGFloat

        var isValid: Bool { maxCenterX >= minCenterX && maxCenterY >= minCenterY }
    }

    private func layoutMetrics(in geo: GeometryProxy) -> SafeBand {
        let safe = geo.safeAreaInsets
        let w = geo.size.width
        let h = geo.size.height
        let half = DraggableChatButtonMetrics.size / 2
        let m = DraggableChatButtonMetrics.edgeMargin
        let minCX = half + m + safe.leading
        let maxCX = w - half - m - safe.trailing
        let minCY = half + m + safe.top
        // Bottom: h − safeBottom − smallMargin − radius (no extra tab-bar “danger zone”).
        let maxCY = h - half - safe.bottom - DraggableChatButtonMetrics.bottomSafeMargin
        return SafeBand(minCenterX: minCX, maxCenterX: maxCX, minCenterY: minCY, maxCenterY: maxCY)
    }

    private func storedCenter(in band: SafeBand) -> CGPoint {
        let nx = CGFloat(storedRelX.clamped(to: 0...1))
        let ny = CGFloat(storedRelY.clamped(to: 0...1))
        let x = band.minCenterX + nx * (band.maxCenterX - band.minCenterX)
        let y = band.minCenterY + ny * (band.maxCenterY - band.minCenterY)
        return CGPoint(x: x, y: y)
    }

    private func clampToSafeBand(_ p: CGPoint, layout band: SafeBand) -> CGPoint {
        let x = min(max(p.x, band.minCenterX), band.maxCenterX)
        let y = min(max(p.y, band.minCenterY), band.maxCenterY)
        return CGPoint(x: x, y: y)
    }
}

private extension Double {
    func clamped(to range: ClosedRange<Double>) -> Double {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
