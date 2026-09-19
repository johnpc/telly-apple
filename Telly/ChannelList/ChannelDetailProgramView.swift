import SwiftUI

/// The channel detail pane's now/next block. Renders the current programme's
/// title, air-time window and elapsed progress plus the upcoming title, or a
/// placeholder when the EPG has no now/next. Uses system foreground styles (the
/// pane sits on the app background, not over dimmed video), reusing the shared
/// `InfoOverlayText` / `ProgramProgress` helpers rather than re-inlining any.
struct ChannelDetailProgramView: View {
    let nowNext: NowNext?
    let nowMs: Int

    var body: some View {
        if InfoOverlayText.hasProgram(nowNext), let now = nowNext?.now {
            VStack(alignment: .leading, spacing: 10) {
                Text("Now Playing").font(.caption).textCase(.uppercase)
                    .foregroundStyle(.secondary)
                Text(now.details.title).font(.title2).fontWeight(.semibold)
                Text("\(InfoOverlayText.timeLabel(now.startMs))–\(InfoOverlayText.timeLabel(now.endMs))")
                    .font(.subheadline).monospacedDigit().foregroundStyle(.secondary)
                if let fraction = ProgramProgress.fraction(
                    nowMs: nowMs, startMs: now.startMs, endMs: now.endMs) {
                    ProgressView(value: fraction).frame(maxWidth: 420)
                }
                if let next = InfoOverlayText.nextTitle(nowNext) {
                    Text("Next: \(next)").font(.callout).foregroundStyle(.secondary)
                }
            }
        } else {
            Text("No programme information").font(.callout).foregroundStyle(.secondary)
        }
    }
}
