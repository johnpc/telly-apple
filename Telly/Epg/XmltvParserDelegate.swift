import Foundation

/// Accumulates `<channel>`/`<programme>` elements while `XMLParser` streams the
/// document. Keeps the first occurrence of each interesting child (element text,
/// `src` for `<icon>`, display form for `<episode-num>`); `XmltvElementReader`
/// turns the collected values into the final structs.
final class XmltvParserDelegate: NSObject, XMLParserDelegate {
    private(set) var channels: [XmltvChannel] = []
    private(set) var programs: [XmltvProgram] = []

    private enum Kind { case channel, programme }
    private struct Context {
        let kind: Kind
        let attributes: [String: String]
        let depth: Int
        var children: [String: String] = [:]
        var childTag: String?
        var childSystem: String?
        var text = ""
    }

    private var context: Context?
    private var depth = 0

    func parser(_ parser: XMLParser, didStartElement name: String, namespaceURI: String?,
                qualifiedName: String?, attributes attrs: [String: String]) {
        depth += 1
        if context == nil, let kind = Self.kind(of: name) {
            context = Context(kind: kind, attributes: attrs, depth: depth)
        } else if var ctx = context, depth == ctx.depth + 1 {
            ctx.childTag = name
            ctx.childSystem = attrs["system"]
            ctx.text = ""
            if name == "icon", ctx.children["icon"] == nil { ctx.children["icon"] = attrs["src"] }
            context = ctx
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        guard var ctx = context, ctx.childTag != nil, depth == ctx.depth + 1 else { return }
        ctx.text += string
        context = ctx
    }

    func parser(_ parser: XMLParser, foundCDATA block: Data) {
        guard let string = String(data: block, encoding: .utf8) else { return }
        self.parser(parser, foundCharacters: string)
    }

    func parser(_ parser: XMLParser, didEndElement name: String, namespaceURI: String?,
                qualifiedName: String?) {
        if var ctx = context, depth == ctx.depth + 1, name == ctx.childTag {
            store(&ctx, tag: name)
            ctx.childTag = nil
            ctx.text = ""
            context = ctx
        } else if let ctx = context, depth == ctx.depth {
            finish(ctx)
            context = nil
        }
        depth -= 1
    }

    /// Records one child's value, first occurrence winning.
    private func store(_ ctx: inout Context, tag: String) {
        guard ctx.children[tag] == nil else { return }
        if tag == "icon" { return }
        if tag == "episode-num" {
            ctx.children[tag] = XmltvEpisodeNum.display(system: ctx.childSystem, text: ctx.text)
            return
        }
        ctx.children[tag] = ctx.text
    }

    private func finish(_ ctx: Context) {
        switch ctx.kind {
        case .channel:
            XmltvElementReader.channel(attributes: ctx.attributes, children: ctx.children)
                .map { channels.append($0) }
        case .programme:
            XmltvElementReader.program(attributes: ctx.attributes, children: ctx.children)
                .map { programs.append($0) }
        }
    }

    private static func kind(of name: String) -> Kind? {
        switch name {
        case "channel": return .channel
        case "programme": return .programme
        default: return nil
        }
    }
}
