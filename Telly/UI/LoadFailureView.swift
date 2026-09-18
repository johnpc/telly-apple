import SwiftUI

/// The error treatment for a failed/timed-out data load: a short, non-technical
/// message and a Retry button that re-invokes the screen's real reload path.
/// Styled like the app's other empty states (`ContentUnavailableView` +
/// `.borderedProminent`) so it reads as one system across iPhone/iPad/tvOS.
struct LoadFailureView: View {
    var title = "Couldn’t load"
    var message = "Check your connection and try again."
    let retry: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label(title, systemImage: "wifi.exclamationmark")
        } description: {
            Text(message)
        } actions: {
            Button("Retry", action: retry)
                .buttonStyle(.borderedProminent)
        }
    }
}

#Preview {
    LoadFailureView(retry: {})
}
