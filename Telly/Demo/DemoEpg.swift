import Foundation

/// The demo guide: a deterministic XMLTV schedule for every live ``DemoContent``
/// channel, generated around `nowMs` so it is always current (a static file would
/// go stale). Anchored to LOCAL MIDNIGHT — yesterday 00:00 through the end of
/// tomorrow — in half-hour slots with 30/60/90-minute programmes whose pattern
/// repeats every 6 h, so every day of every channel starts on the same grid no
/// matter when the demo is installed (the guide looks the same at 09:00 and at
/// 23:55, and acceptance scenarios can name "the next programme" by position).
/// Titles per group (the Android e2e fixture's lists) and rotating synopses give
/// the info panel, search and My List content. Pure over its clock input.
enum DemoEpg {
    /// Whole days before today (so "Yesterday" is fully populated for catch-up).
    static let pastDays = 1
    /// Whole days from today on (today + "Tomorrow" fully populated).
    static let futureDays = 2
    private static let slotMs = 30 * 60_000
    /// Programme lengths in half-hour slots, cycled per channel (12 slots = 6 h).
    private static let lengths = [2, 1, 3, 1, 2, 2, 1]

    /// The scheduled span: local midnight `pastDays` ago up to midnight `futureDays` ahead.
    static func window(nowMs: Int, timeZone: TimeZone) -> Range<Int> {
        GuideGeometry.startOfDay(nowMs, timeZone: timeZone, days: -pastDays)
            ..< GuideGeometry.startOfDay(nowMs, timeZone: timeZone, days: futureDays)
    }

    static func document(nowMs: Int, timeZone: TimeZone = .current) -> XmltvDocument {
        let span = window(nowMs: nowMs, timeZone: timeZone)
        var programs: [XmltvProgram] = []
        for (index, channel) in DemoContent.liveChannels.enumerated() {
            programs += schedule(channel, index: index, fromMs: span.lowerBound, toMs: span.upperBound)
        }
        return XmltvDocument(programs: programs)
    }

    /// One channel's back-to-back programmes across the window.
    private static func schedule(_ channel: M3uChannel, index: Int, fromMs: Int, toMs: Int) -> [XmltvProgram] {
        guard let tvgId = channel.tvgID else { return [] }
        let wording = DemoProgramWording.forGroup(channel.groupTitle ?? "")
        var rows: [XmltvProgram] = []
        var start = fromMs
        var slot = index * 3 + 1   // the first channel opens each day with a 30-min slot
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
