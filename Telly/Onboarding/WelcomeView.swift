import SwiftUI

/// The onboarding empty state: brand, one-line pitch, and the call to action
/// that opens the add-playlist wizard. Ported from the Android welcome screen.
struct WelcomeView: View {
    let onAdd: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "tv")
                .font(.system(size: 72))
                .foregroundStyle(.secondary)
            Text("Telly")
                .font(.largeTitle.bold())
            Text("Add a playlist from your IPTV provider to start watching.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 420)
            Button("Add playlist", action: onAdd)
                .buttonStyle(.borderedProminent)
                .padding(.top, 8)
        }
        .padding(40)
    }
}

#Preview {
    WelcomeView(onAdd: {})
}
