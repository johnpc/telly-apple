#if DEBUG
import Foundation

/// The `-tellyOverlay <name>` launch-flag readers for the live-playback overlay
/// screenshot proofs, split out of ``DebugLaunch`` so that file stays within the
/// source-line budget. Each maps one `-tellyOverlay` value to the overlay the
/// live demo should pin open for the capture; every helper is pure over its
/// explicit `args` (the ``DebugLaunch`` convention).
extension DebugLaunch {
    /// Whether to pin the compact zap overlay open — set by `-tellyOverlay zap`.
    static func forcedZapOverlay(in args: [String]) -> Bool {
        value(for: "-tellyOverlay", in: args) == "zap"
    }

    /// Whether to pin the info overlay open with seeded now/next for the proof —
    /// set by `-tellyOverlay info`.
    static func forcedInfoOverlay(in args: [String]) -> Bool {
        value(for: "-tellyOverlay", in: args) == "info"
    }

    /// Whether to pin the expanded transport overlay open (seeded now/next) for
    /// the live-transport proof — set by `-tellyOverlay transport`.
    static func forcedTransportOverlay(in args: [String]) -> Bool {
        value(for: "-tellyOverlay", in: args) == "transport"
    }

    /// Whether to pin the quick-bar open — set by `-tellyOverlay quickBar`.
    static func forcedQuickBarOverlay(in args: [String]) -> Bool {
        value(for: "-tellyOverlay", in: args) == "quickBar"
    }

    /// Whether to pin the channel panel open — set by `-tellyOverlay panel`.
    static func forcedPanelOverlay(in args: [String]) -> Bool {
        value(for: "-tellyOverlay", in: args) == "panel"
    }
}
#endif
