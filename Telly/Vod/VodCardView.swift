import SwiftUI

/// One Movies-browser poster tile (Apple mirror of Android's `VodScreenCard`):
/// the movie's logo/poster art above its name, with a thin "Continue watching"
/// progress bar shown only when the card carries a resume `progressPermille`.
/// Named `*View` deliberately so it stays coverage-exempt; the pure card model
/// is ``VodCard``.
struct VodCardView: View {
    let card: VodCard

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            poster
            Text(card.item.name)
                .font(.caption)
                .lineLimit(2)
            progressBar
        }
    }

    private var poster: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8).fill(.secondary.opacity(0.2))
            artwork
        }
        .aspectRatio(2.0 / 3.0, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    @ViewBuilder private var artwork: some View {
        if let logo = card.item.logoUrl, let url = URL(string: logo) {
            AsyncImage(url: url) { $0.resizable().scaledToFill() } placeholder: { placeholder }
        } else {
            placeholder
        }
    }

    private var placeholder: some View {
        Image(systemName: "film").font(.largeTitle).foregroundStyle(.secondary)
    }

    @ViewBuilder private var progressBar: some View {
        if let permille = card.progressPermille {
            ProgressView(value: Double(permille), total: 1000).frame(height: 3)
        }
    }
}
