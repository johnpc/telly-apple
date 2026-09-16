import Foundation

/// Converts an XMLTV `<episode-num>` element into TiviMate's display form.
/// xmltv_ns numbers are zero-based "season.episode.part" (each field optional,
/// possibly "index/total"): `0.9.` renders as "S1 E10". Other systems
/// (onscreen et al.) already carry display text and pass through unchanged.
enum XmltvEpisodeNum {
    private static let xmltvNs = "xmltv_ns"

    /// The renderable episode string, or nil when nothing displayable exists.
    static func display(system: String?, text: String?) -> String? {
        guard let value = text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !value.isEmpty else { return nil }
        if system?.trimmingCharacters(in: .whitespacesAndNewlines) == xmltvNs {
            return fromXmltvNs(value)
        }
        return value
    }

    private static func fromXmltvNs(_ value: String) -> String? {
        let fields = value.split(separator: ".", omittingEmptySubsequences: false).map(String.init)
        let season = oneBased(fields.count > 0 ? fields[0] : nil)
        let episode = oneBased(fields.count > 1 ? fields[1] : nil)
        let joined = [season.map { "S\($0)" }, episode.map { "E\($0)" }]
            .compactMap { $0 }.joined(separator: " ")
        return joined.isEmpty ? nil : joined
    }

    /// "9/20" or " 9 " -> 10 (xmltv_ns is zero-based); junk -> nil.
    private static func oneBased(_ field: String?) -> Int? {
        guard let head = field?.split(separator: "/", omittingEmptySubsequences: false)
            .first.map(String.init)?.trimmingCharacters(in: .whitespaces),
              let value = Int(head), value >= 0 else { return nil }
        return value + 1
    }
}
