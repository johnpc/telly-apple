import SwiftUI

/// The guide's day-navigation header control: Previous/Next-day steppers around
/// a live day label, plus the "Now" jump back to the current day + time. Sits
/// above the timeline header, mirroring TiviMate's guide chrome. Prev/Next grey
/// out at the EPG's past/forward horizon (`canPageDay*`). Focusable buttons make
/// it remote-friendly on tvOS and tappable on iPhone/iPad — one shared control.
extension GuideGridScreen {
    var dayNavBar: some View {
        HStack(spacing: 16) {
            Button { model.pageDay(-1) } label: { Image(systemName: "chevron.left") }
                .disabled(!model.canPageDayBack)
            Text(model.dayLabel)
                .font(.subheadline.weight(.semibold))
                .monospacedDigit()
                .frame(minWidth: 132)
            Button { model.pageDay(1) } label: { Image(systemName: "chevron.right") }
                .disabled(!model.canPageDayForward)
            Spacer()
            Button { model.jumpToNow() } label: { Label("Now", systemImage: "clock") }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
    }
}
