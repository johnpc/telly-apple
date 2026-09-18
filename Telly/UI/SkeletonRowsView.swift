import SwiftUI

/// The loading treatment shown while a data screen's first content is still on
/// its way: a stack of muted placeholder rows with a highlight band that sweeps
/// across them. The sweep is gated on Reduce Motion — with it on the rows are
/// simply static muted bars, never an infinite shimmer (mirrors the marquee's
/// `gated(_:reduceMotion:)` opt-out so motion is one app-wide rule).
struct SkeletonRowsView: View {
    var rows = 9
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var sweep = false

    var body: some View {
        VStack(spacing: 12) {
            ForEach(0..<rows, id: \.self) { _ in SkeletonRowView(sweep: sweep) }
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .accessibilityElement()
        .accessibilityLabel("Loading")
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.linear(duration: 1.3).repeatForever(autoreverses: false)) { sweep = true }
        }
    }
}

/// A single placeholder bar: a muted fill with a diagonal highlight the parent
/// drives across it via the `sweep` flag (a no-op under Reduce Motion).
private struct SkeletonRowView: View {
    let sweep: Bool

    var body: some View {
        GeometryReader { geo in
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.secondary.opacity(0.15))
                .overlay {
                    RoundedRectangle(cornerRadius: 8).fill(
                        LinearGradient(colors: [.clear, .secondary.opacity(0.25), .clear],
                                       startPoint: .leading, endPoint: .trailing))
                        .frame(width: geo.size.width * 0.4)
                        .offset(x: sweep ? geo.size.width : -geo.size.width * 0.4)
                }
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .frame(height: 44)
    }
}
