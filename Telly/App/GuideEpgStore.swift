import Foundation

/// Observable now/next feed the guide surfaces read. Snapshots the visible
/// channels, derives their EPG ids (`epgId`) and per-channel offset map, then
/// asks `EpgRepository` for now/next at an injected wall clock and publishes
/// the result. Holds no clock of its own — `now` is supplied like the other
/// `AppEnvironment` factories — so the whole thing is testable at a fixed time.
@MainActor
@Observable
final class GuideEpgStore {
    private let channelStore: ChannelStore
    private let repository: EpgRepository
    private let now: () -> Int

    /// Latest now/next keyed by channel EPG id; empty until the first `refresh`.
    private(set) var nowNextByChannel: [String: NowNext] = [:]

    init(channelStore: ChannelStore, repository: EpgRepository, now: @escaping () -> Int) {
        self.channelStore = channelStore
        self.repository = repository
        self.now = now
    }

    /// Re-queries now/next for every visible channel at the current clock,
    /// applying each channel's EPG time offset. A read failure yields an empty
    /// feed rather than propagating — the guide simply shows no programme info.
    func refresh() {
        let channels = (try? channelStore.visibleChannels()) ?? []
        let epgIds = channels.compactMap(\.epgId)
        let offsets = EpgOffsets.map(for: channels)
        nowNextByChannel = (try? repository.nowNext(
            tvgIds: epgIds, atMs: now(), offsets: offsets)) ?? [:]
    }

    /// Nil-safe lookup for a single channel's now/next — the seam S4's info
    /// overlay wires into `LivePlaybackModel`. Nil id or absent channel → nil.
    func nowNext(forEpgId epgId: String?) -> NowNext? {
        guard let epgId else { return nil }
        return nowNextByChannel[epgId]
    }
}
