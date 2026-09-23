import Foundation

/// The persisted "Buffer size" playback preference over the backing
/// ``KeyValueStore``. Mirrors the `+ChannelSort` tracked-mirror idiom:
/// `bufferSizeRaw` is what the Settings picker binds to (get returns the
/// tracked var, set writes through so SwiftUI observes the change);
/// `bufferSize` derives the typed value the composition root hands each
/// freshly-minted player engine. Engines are built per playback surface, so a
/// changed size applies on the next tune — never hot-swapped into a playing
/// stream. Corrupt / out-of-range raws coerce to `.medium`.
extension SettingsStore {
    /// The stored buffer-size raw value the Settings picker binds to.
    var bufferSizeRaw: Int {
        get { rawBufferSize }
        set { rawBufferSize = newValue; backing.writeInt(newValue, SettingsKey.bufferSize.rawValue) }
    }

    /// The derived buffer preference every engine mint site reads.
    var bufferSize: BufferSize { .from(rawBufferSize) }
}
