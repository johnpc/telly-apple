import SwiftUI

/// The Xtream Codes entry step: the server (host[:port], optional scheme) plus a
/// username and a secure password field, then Next to authenticate + import. The
/// invalid-input and auth-failure messages come from the model's error.
struct WizardXtreamStepView: View {
    let model: AddPlaylistModel

    private var server: Binding<String> { bind(\.server, model.setServer) }
    private var username: Binding<String> { bind(\.username, model.setUsername) }
    private var password: Binding<String> { bind(\.password, model.setPassword) }

    var body: some View {
        Form {
            Section {
                UrlFieldView(placeholder: "http://example.com:8080", text: server,
                             showInvalid: model.state.error == .invalidURL)
                TextField("Username", text: username).textContentType(.username)
                SecureField("Password", text: password)
                if model.state.error == .authFailed {
                    Text("Could not sign in. Check the server and credentials.")
                        .font(.footnote).foregroundStyle(.red)
                }
            } header: {
                Text("Enter your Xtream Codes login")
            }
            Button("Next") { Task { await model.submitXtream() } }
                .disabled(model.state.server.trimmed.isEmpty)
        }
    }

    private func bind(_ path: KeyPath<WizardUiState, String>,
                      _ set: @escaping (String) -> Void) -> Binding<String> {
        Binding(get: { model.state[keyPath: path] }, set: set)
    }
}
