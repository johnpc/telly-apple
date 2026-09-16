import Foundation

/// The playback engine's coarse lifecycle, mirrored 1:1 from the Android
/// `PlayerState` sealed interface. `reconnecting` is the transient state a live
/// stream enters between a dropped connection and its next retry (see
/// ``ReconnectPolicy``); it resolves back to `playing` or to `error`. `ended`
/// is reached only by finite streams (VOD / catch-up / recordings). `error`
/// carries the engine's error description so the UI can surface it.
enum PlayerState: Equatable {
    case idle
    case buffering
    case playing
    case reconnecting
    case ended
    case error(String)
}
