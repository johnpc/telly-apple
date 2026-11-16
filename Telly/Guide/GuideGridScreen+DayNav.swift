import SwiftUI

/// The guide's day-navigation header control: Previous/Next-day steppers around
/// a live day label, plus the "Now" jump back to the current day + time. Sits
/// above the timeline header, mirroring TiviMate's guide chrome. Prev/Next grey
/// out at the EPG's past/forward horizon (`canPageDay*`). Focusable buttons make
/// it remote-friendly on tvOS and tappable on iPhone/iPad — one shared control.
extension GuideGridScreen {
    var dayNavBar: some View {
        HStack(spacing: 16) {
            // Icon-only `Label`s (not bare `Image`s) so the steppers carry a spoken /
            // automatable name ("Previous day" / "Next day") for VoiceOver + XCUITest.
            Button { model.pageDay(-1) } label: {
                Label("Previous day", systemImage: "chevron.left").labelStyle(.iconOnly)
            }
            .disabled(!model.canPageDayBack)
            Text(model.dayLabel)
                .font(.subheadline.weight(.semibold))
                .monospacedDigit()
                .frame(minWidth: 132)
            Button { model.pageDay(1) } label: {
                Label("Next day", systemImage: "chevron.right").labelStyle(.iconOnly)
            }
            .disabled(!model.canPageDayForward)
            Spacer()
            Button { model.jumpToNow() } label: { Label("Now", systemImage: "clock") }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
    }
}
