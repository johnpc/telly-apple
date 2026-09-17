import Foundation

extension ProgramRecord {
    /// Builds a persistence row from a domain programme, flattening the nested
    /// `ProgramDetails` into columns (id 0 => nil so SQLite autoincrements a
    /// fresh primary key on insert; epoch millis widen `Int` => `Int64`).
    init(_ e: ProgramEntity) {
        self.init(
            id: e.id == 0 ? nil : Int64(e.id),
            channelTvgId: e.channelTvgId,
            startMs: Int64(e.startMs),
            endMs: Int64(e.endMs),
            title: e.details.title,
            subTitle: e.details.subTitle,
            description: e.details.description,
            category: e.details.category,
            episode: e.details.episode
        )
    }

    /// The domain programme this row represents, re-nesting `ProgramDetails`.
    var entity: ProgramEntity {
        ProgramEntity(
            id: id.map(Int.init) ?? 0,
            channelTvgId: channelTvgId,
            startMs: Int(startMs),
            endMs: Int(endMs),
            details: ProgramDetails(title: title, subTitle: subTitle, description: description,
                                    category: category, episode: episode)
        )
    }
}
