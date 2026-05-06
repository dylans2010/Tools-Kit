import SwiftUI

struct ConnectorAuthView: View {
    @ObservedObject var connector: AnyBaseConnectorWrapper
    @State private var credentials: [String: String] = [:]
    @Environment(\.dismiss) var dismiss
    @State private var isAuthenticating = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Authentication") {
                    ForEach(connector.authFields, id: \.key) { field in
                        if field.isSecure {
                            SecureField(field.label, text: Binding(
                                get: { credentials[field.key] ?? "" },
                                set: { credentials[field.key] = $0 }
                            ))
                        } else {
                            TextField(field.label, text: Binding(
                                get: { credentials[field.key] ?? "" },
                                set: { credentials[field.key] = $0 }
                            ))
                        }
                    }
                }

                Section {
                    Button(action: authenticate) {
                        if isAuthenticating {
                            ProgressView()
                        } else {
                            Text("Connect")
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .disabled(isAuthenticating)
                }
            }
            .navigationTitle("Configure \(connector.name)")
            .toolbar {
                Button("Cancel") { dismiss() }
            }
        }
    }

    private func authenticate() {
        isAuthenticating = true
        Task {
            do {
                try await connector.authenticate(credentials: credentials)
                await MainActor.run {
                    isAuthenticating = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isAuthenticating = false
                    SDKLogStore.shared.log("Auth failed for \(connector.name): \(error.localizedDescription)", source: "ConnectorAuth", level: .error)
                }
            }
        }
    }
}
