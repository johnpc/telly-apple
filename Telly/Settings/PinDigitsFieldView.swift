import SwiftUI

/// The raw masked digit field shared by the PIN set/change sheet and (a later
/// slice's) challenge sheet, so neither duplicates the `SecureField` wiring.
/// Masks input, keeps only the first ``PinPolicy/length`` decimal digits, and
/// never logs what is typed. A pure leaf view — no business logic.
struct PinDigitsFieldView: View {
    @Binding var pin: String

    var body: some View {
        SecureField("PIN", text: $pin)
            .textContentType(.oneTimeCode)
            .multilineTextAlignment(.center)
            .font(.title2.monospacedDigit())
        #if os(iOS)
            .keyboardType(.numberPad)
        #endif
            .onChange(of: pin) { _, new in
                pin = String(new.prefix(PinPolicy.length).filter(\.isNumber))
            }
    }
}
