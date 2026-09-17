import SwiftUI

/// One quick-bar slot: an SF Symbol in a translucent circle above its label,
/// laid out to share the bar width equally with its eight siblings.
struct QuickBarSlotView: View {
    let symbol: String
    let label: String

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: symbol)
                .font(.title2)
                .frame(width: 64, height: 64)
                .background(Circle().fill(.white.opacity(0.15)))
            Text(label)
                .font(.caption)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
    }
}
