import Foundation

/// Which layer currently covers the fullscreen video — ported from the Android
/// `PlaybackOverlay` sealed interface. `pushed` mirrors Android's nested
/// `Pushed` sub-interface: any screen stacked on top of another overlay whose
/// BACK pops to `back` (hence `indirect`). Android's concrete pushed subtypes
/// (ComingSoon / Description / ChannelOptions / RecordingStop / CustomRecording
/// / BlockPin / TrackPicker / GroupTool) collapse to the ported ``PushedSheet``
/// cases; the S1 key policy treats every pushed screen the same (BACK pops to
/// `back`), so one `pushed(sheet, back:)` case stays faithful.
indirect enum PlaybackOverlay: Equatable, Sendable {
    /// Bare playback: zero chrome.
    case none
    /// Bottom info overlay with programme data + shortcut cards.
    case info
    /// Info overlay expanded with the transport row.
    case infoTransport
    /// Compact channel-change overlay while the new stream tunes.
    case zapInfo
    /// Bottom icon quick-bar from long-OK / MENU at fullscreen.
    case quickBar
    /// Channel list panel over the dimmed video.
    case panel
    /// Right-side sheet from long-OK on a panel row; BACK returns to the panel.
    case channelMenu(channelId: Int64)
    /// The N-up multiview grid over the dimmed video; OK promotes the active
    /// tile to fullscreen, MENU/BACK exit back to single-stream playback.
    case multiview
    /// A card pushed on top of another overlay — WHICH card is part of the
    /// state (no sibling flags to keep in sync); BACK pops to `back`.
    case pushed(PushedSheet, back: PlaybackOverlay)
}

/// The cards the live player can push over the quick-bar. Carried inside
/// ``PlaybackOverlay/pushed(_:back:)`` so "a sheet is up" and "which sheet" are
/// one value: dismissing the overlay closes the card by construction, and the
/// screen renders exactly one card per state.
enum PushedSheet: Equatable, Sendable {
    /// The audio / captions / audio-sync picker for one ``TrackPickerKind``.
    case trackPicker(TrackPickerKind)
    /// The aspect-ratio (``ResizeMode``) picker.
    case resizePicker
}
