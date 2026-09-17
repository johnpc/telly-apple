import CoreGraphics

/// Runtime viewport sizing for the guide grid. `GuideGridScreen` measures the
/// on-screen width remaining after the fixed channel column and feeds it here so
/// the timeline fills the device instead of a fixed default, on every platform.
/// Re-materialising re-derives every width-dependent value (rows, header ticks,
/// now-line) through the same path as `load`/scroll.
extension GuideGridModel {
    /// Sets the programme-pane viewport to `width` and re-materialises the
    /// window. Ignores non-positive or unchanged widths to avoid needless work.
    /// `scrollX` needs no re-clamp: its floor/ceil are viewport-independent.
    func setViewport(_ width: CGFloat) {
        guard width > 0, width != viewport else { return }
        viewport = width
        materializeRows()
    }
}
