import Foundation

/// One card of the Channels shelf: the channel, its currently-airing programme
/// title in accent blue and a thin progress line. Ported from Android
/// `SearchChannelHit` — permille progress replaced by the app's `Double?` seam.
struct SearchChannelHit: Equatable {
    let channel: ChannelEntity
    let nowTitle: String?
    let progress: Double?
}

/// One airing row of the Programs pane: the programme, the channel it airs on
/// and its formatted air time. Currently-airing rows also carry the dash
/// progress + "N min" remaining after the times; both stay nil for upcoming.
struct SearchProgramHit: Equatable {
    let program: ProgramEntity
    let channel: ChannelEntity
    let title: String
    let timeText: String
    let progress: Double?
    let remaining: String?
}

/// One master-lane card of the Programs section: a channel with at least one
/// matching programme and ALL of its matching airings, chronological — one row
/// per airing, never deduped by title, never merged across channels.
struct SearchProgramChannel: Equatable {
    let channel: ChannelEntity
    let airings: [SearchProgramHit]
}

/// Everything the typed search state renders; empty query = empty shelves.
struct SearchResults: Equatable {
    var query: String = ""
    var channels: [SearchChannelHit] = []
    var programs: [SearchProgramChannel] = []

    var isEmpty: Bool { channels.isEmpty && programs.isEmpty }
}
