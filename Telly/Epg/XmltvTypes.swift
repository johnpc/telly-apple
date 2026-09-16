import Foundation

/// Descriptive programme fields shared by the XMLTV parser and persistence.
/// `episode` is already converted to display form ("S1 E10") by the parser.
struct ProgramDetails: Equatable {
    let title: String
    var subTitle: String?
    var description: String?
    var category: String?
    var episode: String?
}

/// A `<channel>` element from an XMLTV document.
struct XmltvChannel: Equatable {
    let id: String
    var displayName: String?
    var iconUrl: String?
}

/// A `<programme>` element with its start/stop resolved to epoch millis.
struct XmltvProgram: Equatable {
    let channelId: String
    let startMs: Int
    let endMs: Int
    let details: ProgramDetails
}

/// Everything parsed from one XMLTV document.
struct XmltvDocument: Equatable {
    var channels: [XmltvChannel] = []
    var programs: [XmltvProgram] = []
}

/// One guide programme keyed to a channel by tvg-id (the XMLTV `channel`
/// attribute). Mirrors the Android `ProgramEntity` so query/fold logic ports 1:1.
struct ProgramEntity: Equatable {
    var id: Int = 0
    let channelTvgId: String
    let startMs: Int
    let endMs: Int
    let details: ProgramDetails
}
