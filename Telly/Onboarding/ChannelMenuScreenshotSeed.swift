#if DEBUG
import SwiftUI

/// DEBUG-only screenshot proof for the consolidated per-channel "Channel options"
/// menu: with `-tellySeedBase <url> -tellyChannelMenu` it auto-opens the menu on
/// the first visible channel (via ``channelMenuProof``), so a plain `simctl`
/// screenshot captures the rows without any long-press tooling. Adding
/// `-tellySeedFavorite` first flags that channel favourite so the row reads
/// "Remove from Favorites" — the flipped-state variation. Never touches the real
/// provider. Follows the guide cell-menu (`GuideMenuScreenshotSeed`) idiom.
enum ChannelMenuScreenshotSeed {
    @MainActor
    static func present(_ target: Binding<ChannelEntity?>, model: ChannelListModel) async {
        guard CommandLine.arguments.contains("-tellyChannelMenu") else { return }
        for _ in 0..<50 where model.rows.isEmpty { try? await Task.sleep(nanoseconds: 100_000_000) }
        target.wrappedValue = model.rows.first
    }
}
#endif
