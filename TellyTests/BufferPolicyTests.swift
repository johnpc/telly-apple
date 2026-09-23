import Testing
@testable import Telly

/// The pure buffer policy (the network-caching fix for the live stutter bug)
/// and its persisted Settings seam: exact option strings per size, the Medium
/// default, persistence round-trips, corrupt-raw coercion, reset and backup.
@MainActor
struct BufferPolicyTests {
    private func store() -> SettingsStore { SettingsStore(backing: InMemoryKeyValueStore()) }

    @Test func optionStringsPerSize() {
        #expect(BufferPolicy.mediaOptions(for: .small)
            == [":network-caching=3000", ":http-reconnect"])
        #expect(BufferPolicy.mediaOptions(for: .medium)
            == [":network-caching=6000", ":http-reconnect"])
        #expect(BufferPolicy.mediaOptions(for: .large)
            == [":network-caching=12000", ":http-reconnect"])
    }

    @Test func everySizeBuffersMoreThanTheStockVlcSecond() {
        for size in BufferSize.allCases { #expect(size.cachingMs > 1_000) }
    }

    @Test func sizesGrowMonotonically() {
        #expect(BufferSize.small.cachingMs < BufferSize.medium.cachingMs)
        #expect(BufferSize.medium.cachingMs < BufferSize.large.cachingMs)
    }

    @Test func defaultIsMedium() {
        #expect(SettingsDefaults.bufferSize == BufferSize.medium.rawValue)
        #expect(store().bufferSize == .medium)
    }

    @Test func pickPersistsThroughTheBackingStore() {
        let s = store()
        s.bufferSizeRaw = BufferSize.large.rawValue
        #expect(s.bufferSize == .large)
        #expect(SettingsStore(backing: s.backing).bufferSize == .large)
    }

    @Test func corruptRawsCoerceToMedium() {
        let s = store()
        s.backing.writeInt(99, SettingsKey.bufferSize.rawValue)
        #expect(SettingsStore(backing: s.backing).bufferSize == .medium)
        s.backing.writeInt(-1, SettingsKey.bufferSize.rawValue)
        #expect(SettingsStore(backing: s.backing).bufferSize == .medium)
    }

    @Test func resetRestoresTheMediumDefault() {
        let s = store()
        s.bufferSizeRaw = BufferSize.small.rawValue
        s.resetToDefaults()
        #expect(s.bufferSize == .medium)
        #expect(s.bufferSizeRaw == SettingsDefaults.bufferSize)
    }

    @Test func backupSnapshotCarriesThePick() {
        let source = store()
        source.bufferSizeRaw = BufferSize.large.rawValue
        let restored = InMemoryKeyValueStore()
        SettingsSnapshot.restore(SettingsSnapshot.snapshot(from: source.backing), into: restored)
        #expect(SettingsStore(backing: restored).bufferSize == .large)
    }

    @Test func pickerTitlesAreDistinct() {
        #expect(Set(BufferSize.allCases.map(\.title)).count == BufferSize.allCases.count)
        #expect(Set(BufferSize.allCases.map(\.id)).count == BufferSize.allCases.count)
    }
}
