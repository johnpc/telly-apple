import Foundation

/// Streaming XMLTV parser. Foundation's `XMLParser` is push/SAX (unlike
/// Android's pull parser), so a delegate accumulates one `<channel>`/
/// `<programme>` at a time. Tolerant of missing fields; skips programmes it
/// cannot key or time. Ported from the Android `XmltvParser`.
enum XmltvParser {
    /// Parses one XMLTV document from `data`, returning whatever was parseable.
    static func parse(_ data: Data) -> XmltvDocument {
        let parser = XMLParser(data: data)
        let delegate = XmltvParserDelegate()
        parser.delegate = delegate
        parser.parse()
        return XmltvDocument(channels: delegate.channels, programs: delegate.programs)
    }
}
