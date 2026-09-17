import SwiftUI

/// The "Parental Controls" settings group: a master enable toggle plus PIN
/// management. The enable flag binds straight to the ``ParentalStore`` (its
/// KeyValueStore-backed toggle); setting, changing or clearing the PIN routes
/// through the masked ``PinEntrySheetView`` so the raw PIN never lands here.
/// Tune-time enforcement is a later slice — this is presentation + PIN plumbing.
struct SettingsParentalSectionView: View {
    @Bindable var parental: ParentalStore
    @State private var entry: PinEntryMode?

    var body: some View {
        Section("Parental Controls") {
            Toggle("Require PIN for Locked Channels", isOn: $parental.isEnabled)
            Button(parental.isSet ? "Change PIN" : "Set PIN") { entry = .set }
            if parental.isSet {
                Button("Disable PIN", role: .destructive) { entry = .disable }
            }
        }
        .sheet(item: $entry) { mode in
            PinEntrySheetView(mode: mode) { submit(mode, $0) }
        }
    }

    /// Applies the entered PIN for `mode`, returning whether it was accepted so
    /// the sheet dismisses (accepted) or clears for a retry (wrong current PIN).
    private func submit(_ mode: PinEntryMode, _ pin: String) -> Bool {
        switch mode {
        case .set:
            return parental.set(pin: pin)
        case .disable:
            guard parental.verify(pin: pin) else { return false }
            parental.clear()
            return true
        }
    }
}
