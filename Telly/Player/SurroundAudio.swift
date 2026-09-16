import Foundation

/// "Select surround audio track by default": prefers the audio track with the
/// most channels. Returns nil when the current selection already has as many
/// channels (so applying the returned pick never loops) or when no track beats
/// it. Pure port of the Android `SurroundAudio.pick` reduced to plain data.
enum SurroundAudio {
    /// The audio-track id to switch to so the highest-channel track plays by
    /// default, or nil to leave the current pick. Returns nil when the best
    /// track doesn't beat the currently-selected track's channel count.
    static func pick(audios: [AudioTrack], selectedId: String?) -> String? {
        guard let best = audios.max(by: { $0.channels < $1.channels }) else { return nil }
        let selected = audios.first(where: { $0.id == selectedId })?.channels ?? 0
        return best.channels > selected ? best.id : nil
    }
}
