import SwiftUI

/// The onboarding empty state: brand, one-line pitch, the call to action that
/// opens the add-playlist wizard, and a second door — the built-in demo playlist
/// (``DemoContent``) — so a first-time user, an App Store reviewer or a CI run can
/// explore the whole app without any provider. Ported from the Android welcome.
struct WelcomeView: View {
    let onAdd: () -> Void
    let onDemo: () -> Void

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
                .accessibilityIdentifier("welcome.add")
                .padding(.top, 8)
            Button("Try the demo playlist", action: onDemo)
                .buttonStyle(.bordered)
                .accessibilityIdentifier("welcome.demo")
            Text("A built-in sample guide over public test streams — no provider needed.")
                .font(.footnote)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 420)
        }
        .padding(40)
    }
}

#Preview {
    WelcomeView(onAdd: {}, onDemo: {})
}
