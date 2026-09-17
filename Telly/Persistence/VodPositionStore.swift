import GRDB

/// Resume-position policy over the `vod_positions` table — the Apple mirror of
/// the Android `VodPositionStore`. Both seams are injected: `remember` gates all
/// reads/writes behind the "Remember playback position" setting, and `clock`
/// supplies the write timestamp (no wall-clock reads in logic). Finished items
/// clear their row and unknown durations are never persisted — see
/// `VodResumePolicy`.
struct VodPositionStore {
    let db: AppDatabase
    let remember: () -> Bool
    let clock: () -> Int64

    /// The stored position for `itemKey`, or nil while "remember" is off.
    func read(itemKey: String) throws -> VodPosition? {
        guard remember() else { return nil }
        return try db.queue.read {
            try VodPositionRecord.filter(Column("itemKey") == itemKey).fetchOne($0)?.entity
        }
    }

    /// Media end: position == duration counts as finished, clearing the row.
    func finish(itemKey: String, durationMs: Int) throws {
        try save(itemKey: itemKey, positionMs: durationMs, durationMs: durationMs)
    }

    /// Upserts a mid-band position; finished (>95%) deletes the row. No-op while
    /// "remember" is off or the duration is unknown (≤0).
    func save(itemKey: String, positionMs: Int, durationMs: Int) throws {
        guard remember(), durationMs > 0 else { return }
        if VodResumePolicy.finished(positionMs: positionMs, durationMs: durationMs) {
            try db.queue.write { _ = try VodPositionRecord.filter(Column("itemKey") == itemKey).deleteAll($0) }
        } else {
            let position = VodPosition(itemKey: itemKey, positionMs: positionMs,
                                       durationMs: durationMs, updatedAtMs: Int(clock()))
            try db.queue.write { try VodPositionRecord(position).insert($0, onConflict: .replace) }
        }
    }

    /// Every stored position (Settings clear/debug seeding).
    func all() throws -> [VodPosition] {
        try db.queue.read { try VodPositionRecord.fetchAll($0).map(\.entity) }
    }

    /// Empties all stored positions (Settings → Clear playback positions).
    func clear() throws {
        try db.queue.write { _ = try VodPositionRecord.deleteAll($0) }
    }
}
