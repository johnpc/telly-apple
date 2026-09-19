import Foundation
@testable import Telly

/// In-memory ``SyncedConfigStore`` fake for tests — a single optional slot
/// mirroring ``InMemorySecretStore``. Lets the wiring/restore tests run without
/// touching the real (synchronizable) Keychain; an unsaved store reads back nil.
final class InMemorySyncedConfigStore: SyncedConfigStore {
    private(set) var value: SyncedConfig?
    private(set) var saves = 0
    private(set) var clears = 0

    func load() -> SyncedConfig? { value }
    func save(_ config: SyncedConfig) { value = config; saves += 1 }
    func clear() { value = nil; clears += 1 }
}
