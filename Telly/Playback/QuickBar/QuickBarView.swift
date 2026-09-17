import SwiftUI

/// The fullscreen quick-bar: nine evenly-spaced icon+label slots over the shared
/// ``BottomOverlayBar`` scrim, ported from the Android quick-bar. Labels come
/// from the pure ``QuickBarItems`` (the four stream-derived slots read `video`);
/// OK-activation and d-pad focus are a later slice. On a compact iPhone the fixed
/// slots overflow the screen, so there the row becomes a leading-aligned
/// horizontal ScrollView (every slot reachable); tvOS and regular width keep the
/// centred fixed row — a ScrollView on tvOS would break D-pad focus.
struct QuickBarView: View {
    let video: VideoDetails?
    #if !os(tvOS)
    @Environment(\.horizontalSizeClass) private var sizeClass
    #endif

    var body: some View {
        BottomOverlayBar { bar }
    }

    #if os(tvOS)
    private var bar: some View { row }
    #else
    @ViewBuilder private var bar: some View {
        if sizeClass == .compact {
            ScrollView(.horizontal, showsIndicators: false) { row }
        } else {
            row
        }
    }
    #endif

    private var row: some View {
        HStack(alignment: .top, spacing: 12) {
            ForEach(QuickBarItems.items(video: video), id: \.action) { item in
                QuickBarSlotView(symbol: icon(for: item.action), label: item.label)
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
