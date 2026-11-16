import Foundation

/// The demo guide: a deterministic XMLTV schedule for every live ``DemoContent``
/// channel, generated around `nowMs` so it is always current (a static file would
/// go stale). Covers the past 30 hours and the next two days in half-hour slots, with
/// 30/60/90-minute programmes, titles per group (the Android e2e fixture's lists)
/// and rotating synopses so the info panel, search and My List all have content.
/// Pure over its clock input, so every row is unit-testable.
enum DemoEpg {
    /// 30 h back so "Yesterday" in the guide is populated (catch-up demo).
    static let pastHours = 30
    /// 48 h ahead so "Tomorrow" in the guide is fully populated too.
    static let futureHours = 48
    private static let slotMs = 30 * 60_000
    /// Programme lengths in half-hour slots, cycled per channel.
    private static let lengths = [2, 1, 3, 1, 2, 2, 1]

    static func document(nowMs: Int, timeZone: TimeZone = .current) -> XmltvDocument {
        let origin = GuideGeometry.halfHourFloor(nowMs, timeZone: timeZone) - pastHours * 60 * 60_000
        let endMs = origin + (pastHours + futureHours) * 60 * 60_000
        var programs: [XmltvProgram] = []
        for (index, channel) in DemoContent.liveChannels.enumerated() {
            programs += schedule(channel, index: index, fromMs: origin, toMs: endMs)
        }
        return XmltvDocument(programs: programs)
    }

    /// One channel's back-to-back programmes across the window.
    private static func schedule(_ channel: M3uChannel, index: Int, fromMs: Int, toMs: Int) -> [XmltvProgram] {
        guard let tvgId = channel.tvgID else { return [] }
        let wording = DemoProgramWording.forGroup(channel.groupTitle ?? "")
        var rows: [XmltvProgram] = []
        var start = fromMs
        var slot = index * 3
        while start < toMs {
            let end = min(toMs, start + lengths[slot % lengths.count] * slotMs)
            let details = ProgramDetails(
                title: wording.titles[slot % wording.titles.count],
                description: DemoProgramWording.descriptions[(index + slot) % DemoProgramWording.descriptions.count],
                category: wording.category)
            rows.append(XmltvProgram(channelId: tvgId, startMs: start, endMs: end, details: details))
            start = end
            slot += 1
        }
        return rows
    }
}

/// The demo guide's wording per group (ported from the Android e2e fixture
/// generator), kept as one `group|category|title|title…` table.
struct DemoProgramWording: Equatable {
    let category: String
    let titles: [String]

    static func forGroup(_ group: String) -> DemoProgramWording {
        let row = table.first { $0.first == group } ?? table.last ?? ["", ""]
        return DemoProgramWording(category: row[1], titles: Array(row.dropFirst(2)))
    }

    private static let table: [[String]] = """
    News|News|Morning Report|World News Now|The Daily Brief|Politics Tonight|Business Hour|Weather Watch|Global Update|Newsroom Live
    Sports|Sports|Match of the Day|Championship Live|Sports Center|The Halftime Show|Boxing Classics|Motorsport Weekly|Tennis Masters|Extreme Games
    Movies|Movie / Drama|The Long Road Home|Midnight in Berlin|Chasing Shadows|The Last Stand|Summer of '89|Iron Harvest|The Quiet Hour|City of Glass
    Kids|Children's / Youth|Puppy Patrol|Space Cadets|The Magic Treehouse|Dino Explorers|Robot Friends|Fairy Tale Theater|Junior Chefs|Ocean Adventures
    Music|Music / Ballet / Dance|Top 40 Countdown|Classic Rock Block|Jazz After Dark|Electronic Sessions|Country Roads|Hip Hop Nation|Symphony Hall|Indie Discoveries
    """.split(separator: "\n").map { $0.split(separator: "|").map(String.init) }

    static let descriptions = [
        "An in-depth look at the stories shaping our world today, with expert analysis and live reports from the field.",
        "Join our hosts for the latest updates, interviews and highlights you won't want to miss.",
        "A fan-favorite returns with more surprises, bigger moments and unforgettable characters.",
        "Critics call it 'a triumph' - experience the acclaimed hit everyone is talking about.",
        "All-new episode featuring special guests and exclusive behind-the-scenes footage.",
        "The definitive guide to what's happening now, presented by our award-winning team.",
    ]
}
