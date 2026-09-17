import Foundation

/// The D-pad and media-remote keys fullscreen playback reacts to, mapped from
/// platform key events by the (un-ported) UI layer. Ported 1:1 from the Android
/// `PlaybackKey` enum. `rewind` / `fastForward` are inert at bare playback —
/// Android routes them only through the catch-up context (a later slice) — but
/// they stay in the vocabulary so the remote-key surface is complete and the
/// policy can name them explicitly.
enum PlaybackKey: Sendable {
    case ok
    case longOk
    case menu
    case back
    case up
    case down
    case left
    case right
    case channelUp
    case channelDown
    case rewind
    case fastForward
}
