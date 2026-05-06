import SwiftUI

struct ConnectorAuthView<T: BaseConnector>: View {
    @ObservedObject var connector: T
    @Environment(\.dismiss) var dismiss
    @State private var credentials: [String: String] = [:]
    @State private var isAuthenticating = false
    @State private var error: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Authentication Fields") {
                    ForEach(connector.authFields, id: \.key) { field in
                        if field.isSecure {
                            SecureField(field.label, text: binding(for: field.key))
                        } else {
                            TextField(field.label, text: binding(for: field.key))
                        }
                    }
                }

                if let error = error {
                    Section {
                        Text(error).foregroundStyle(.red)
                    }
                }

                Section {
                    Button {
                        authenticate()
                    } label: {
                        if isAuthenticating {
                            ProgressView().progressViewStyle(.circular)
                        } else {
                            Text("Connect")
                        }
                    }
                    .disabled(isAuthenticating)
                }
            }
            .navigationTitle("Authenticate \(connector.name)")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func binding(for key: String) -> Binding<String> {
        Binding(
            get: { credentials[key] ?? "" },
            set: { credentials[key] = $0 }
        )
    }

    private func authenticate() {
        isAuthenticating = true
        error = nil
        Task {
            do {
                try await connector.authenticate(credentials: credentials)
                await MainActor.run {
                    isAuthenticating = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    self.error = error.localizedDescription
                    isAuthenticating = false
                }
            }
        }
    }
}
