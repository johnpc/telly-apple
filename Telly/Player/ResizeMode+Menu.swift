import Foundation

extension ResizeMode {
    /// The picker label for this mode (also the TiviMate/VLC control name).
    var title: String {
        switch self {
        case .fit: return "Fit"
        case .fill: return "Fill"
        case .zoom: return "Zoom"
        case .ratio16x9: return "16:9"
        case .ratio4x3: return "4:3"
        case .fixedWidth: return "Fixed width"
        case .fixedHeight: return "Fixed height"
        }
    }

    /// The modes offered in the player picker, in display order — the TiviMate
    /// set. The legacy `fixed*` modes are store-string-only and omitted here.
    static var selectable: [ResizeMode] { [.fit, .fill, .ratio16x9, .ratio4x3, .zoom] }

    /// The next selectable mode, wrapping — the "cycle aspect" affordance.
    func next() -> ResizeMode {
        let modes = Self.selectable
        guard let index = modes.firstIndex(of: self) else { return modes[0] }
        return modes[(index + 1) % modes.count]
    }
}

/// The aspect-ratio picker's pure rows and id↔mode mapping, mirroring
/// ``TrackPickerRows``. Row ids are the mode's stable `Int` raw value as a
/// string, so a selected row round-trips regardless of case order.
enum ResizeModeChoices {
    static let title = "Aspect ratio"

    static func rows(selected: ResizeMode) -> [TrackPickerRow] {
        ResizeMode.selectable.map {
            TrackPickerRow(id: String($0.rawValue), label: $0.title, checked: $0 == selected)
        }
    }

    /// Resolves a row id back to a selectable mode; nil for an unknown id.
    static func mode(forId id: String) -> ResizeMode? {
        guard let mode = Int(id).flatMap(ResizeMode.init(rawValue:)),
              ResizeMode.selectable.contains(mode) else { return nil }
        return mode
    }
}
