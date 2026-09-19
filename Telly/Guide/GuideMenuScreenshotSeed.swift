#if DEBUG
import SwiftUI

/// DEBUG-only screenshot proof for the guide cell's My List menu: with
/// `-tellyGuide -tellyGuideMenu` it auto-opens the menu on the first future
/// info-cell (the same cell a real OK/tap would open via
/// ``GuideGridModel/cellMenuTarget(for:row:)``), so a plain `simctl` screenshot
/// captures the affordance without any tap tooling. Adding `-tellyGuideMenuSaved`
/// first snapshots that programme into My List so the row reads "Remove from My
/// List" — the mirror of Android's flipped `MyListKeys.label`. Never touches the
/// real provider. Follows the `-tellyMyListSeed` / `forcedMultiviewOverlay` idiom.
enum GuideMenuScreenshotSeed {
    @MainActor
    static func present(_ target: Binding<GuideCellMenuTarget?>, model: GuideGridModel) async {
        let args = CommandLine.arguments
        guard args.contains("-tellyGuideMenu") else { return }
        for _ in 0..<50 where model.rows.isEmpty { try? await Task.sleep(nanoseconds: 100_000_000) }
        guard let hit = model.firstCellMenuTarget() else { return }
        if args.contains("-tellyGuideMenuSaved") { model.ensureSaved(hit) }
        target.wrappedValue = hit
    }
}
#endif
