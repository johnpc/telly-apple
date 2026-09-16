import SwiftUI

/// A reusable http(s) URL text field with keyboard tuning and an inline
/// "invalid URL" line — shared by the wizard's playlist- and EPG-URL steps so
/// the two never drift.
struct UrlFieldView: View {
    let placeholder: String
    let text: Binding<String>
    let showInvalid: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            urlField
            if showInvalid {
                Text("Enter a valid http(s) URL")
                    .font(.footnote)
                    .foregroundStyle(.red)
            }
        }
    }

    @ViewBuilder private var urlField: some View {
        let field = TextField(placeholder, text: text)
        #if os(iOS)
        field
            .textInputAutocapitalization(.never)
            .keyboardType(.URL)
            .autocorrectionDisabled()
        #else
        field
        #endif
    }
}
