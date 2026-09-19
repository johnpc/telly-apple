import SwiftUI

/// Pure size-class layout decisions for the narrow iPhone surfaces, kept out of
/// the views so each rule is unit-tested rather than left to visual capture.
/// `.compact` is the narrow iPhone width; iPad and tvOS report `.regular`.
enum CompactLayout {
    /// Whether the search results' preselected detail card should render. On a
    /// compact width a tap merely tunes, so the floating card is redundant and
    /// awkward there; iPad / tvOS / regular width keep it beside the master-lane.
    static func showsPreselectedCard(_ sizeClass: UserInterfaceSizeClass?) -> Bool {
        sizeClass != .compact
    }

    /// Whether the group strip should auto-scroll to reveal the selected group.
    /// Only the compact iPhone strip can push a chip off-screen; iPad frames the
    /// full strip and tvOS scrolls it through the focus engine, so both opt out.
    static func autoScrollsGroupStrip(_ sizeClass: UserInterfaceSizeClass?) -> Bool {
        sizeClass == .compact
    }

    /// The adaptive minimum width for a Movies-browser poster column. Compact
    /// iPhone width needs a smaller tile so portrait still lands ≥3 columns; iPad
    /// / tvOS / regular keep the poster-scale 168 that fills their wide canvas
    /// with fewer columns instead of a stranded trailing gutter.
    static func posterColumnMinimum(_ sizeClass: UserInterfaceSizeClass?) -> CGFloat {
        sizeClass == .compact ? 100 : 168
    }
}
