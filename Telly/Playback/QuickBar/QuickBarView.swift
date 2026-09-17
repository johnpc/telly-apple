import SwiftUI

/// The fullscreen quick-bar: nine evenly-spaced icon+label slots over the shared
/// ``BottomOverlayBar`` scrim, ported from the Android quick-bar. Labels come
/// from the pure ``QuickBarItems`` (the four stream-derived slots read `video`);
/// OK-activation and d-pad focus are a later slice.
struct QuickBarView: View {
    let video: VideoDetails?

    var body: some View {
        BottomOverlayBar {
            HStack(alignment: .top, spacing: 12) {
                ForEach(QuickBarItems.items(video: video), id: \.action) { item in
                    QuickBarSlotView(symbol: icon(for: item.action), label: item.label)
                }
            }
        }
    }

    private func icon(for action: QuickBarAction) -> String {
        Self.icons[action, default: "square"]
    }

    private static let icons: [QuickBarAction: String] = [
        .search: "magnifyingglass", .channelsList: "list.bullet",
        .recordings: "record.circle", .multiview: "rectangle.split.2x2",
        .pictureInPicture: "pip", .resolution: "4k.tv",
        .audio: "speaker.wave.2.fill", .latency: "timer",
        .subtitles: "captions.bubble",
    ]
}
