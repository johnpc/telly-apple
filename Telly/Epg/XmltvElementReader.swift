import Foundation

/// Pure builders that turn one element's collected attributes + child values
/// into a channel/programme, applying the same tolerance as the Android
/// `XmltvElementReader`: skip anything missing its mandatory fields.
enum XmltvElementReader {
    /// Returns the channel, or nil when the mandatory `id` is missing.
    static func channel(attributes: [String: String], children: [String: String]) -> XmltvChannel? {
        guard let id = attributes["id"],
              !id.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
        return XmltvChannel(id: id, displayName: children["display-name"], iconUrl: children["icon"])
    }

    /// Returns the programme, or nil when channel/start/stop/title are unusable.
    static func program(attributes: [String: String], children: [String: String]) -> XmltvProgram? {
        guard let channelId = attributes["channel"],
              !channelId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let title = children["title"],
              !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let startMs = XmltvTimestamp.parseMs(attributes["start"]),
              let endMs = XmltvTimestamp.parseMs(attributes["stop"]) else { return nil }
        let details = ProgramDetails(
            title: title,
            subTitle: children["sub-title"],
            description: children["desc"],
            category: children["category"],
            episode: children["episode-num"])
        return XmltvProgram(channelId: channelId, startMs: startMs, endMs: endMs, details: details)
    }
}
