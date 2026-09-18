import CoreGraphics

/// Pure ping-pong marquee maths for a single line of text that is wider than the
/// space it is given. Given the measured text width, its container width and the
/// seconds elapsed since the scroll began, it yields the horizontal offset to
/// apply (always `<= 0`: the text slides left to reveal its tail, pauses, then
/// slides back). View-free so the timing is unit-testable headlessly; the
/// `MarqueeTextView` glue only measures widths and feeds a clock in.
enum MarqueeMetrics {
    /// Scroll speed in points per second (gentle, TiviMate-like).
    static let speed: CGFloat = 32
    /// Seconds held still at each end before reversing.
    static let endPause: Double = 1.0

    /// Hidden overflow: how many points of text extend past the container
    /// (0 when it fits). A sub-point sliver counts as fitting.
    static func overflow(textWidth: CGFloat, containerWidth: CGFloat) -> CGFloat {
        max(0, textWidth - containerWidth)
    }

    /// Whether `textWidth` overflows `containerWidth` enough to be worth scrolling.
    static func overflows(textWidth: CGFloat, containerWidth: CGFloat) -> Bool {
        overflow(textWidth: textWidth, containerWidth: containerWidth) > 0.5
    }

    /// Horizontal offset at `elapsed` seconds into the loop. The cycle is
    /// pause → slide left → pause → slide back, so the text rests aligned at both
    /// extremes. Returns 0 (no movement) when the text fits or before time starts.
    static func offset(textWidth: CGFloat, containerWidth: CGFloat, elapsed: Double) -> CGFloat {
        let over = overflow(textWidth: textWidth, containerWidth: containerWidth)
        guard over > 0.5, elapsed > 0 else { return 0 }
        let travel = Double(over) / Double(speed)
        return -over * CGFloat(revealFraction(elapsed: elapsed, travel: travel))
    }

    /// Fraction of the overflow revealed at `elapsed`: 0 while resting aligned,
    /// ramping to 1 fully left across one `travel` leg, holding, then ramping
    /// back — one pause→out→pause→back loop of `travel` seconds per leg.
    private static func revealFraction(elapsed: Double, travel: Double) -> Double {
        let cycle = 2 * (endPause + travel)
        let t = elapsed.truncatingRemainder(dividingBy: cycle)
        if t < endPause { return 0 }
        let out = t - endPause
        if out < travel { return out / travel }
        let held = out - travel
        if held < endPause { return 1 }
        return 1 - (held - endPause) / travel
    }
}
