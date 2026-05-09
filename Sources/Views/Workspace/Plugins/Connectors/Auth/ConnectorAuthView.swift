/*
 REDESIGN SUMMARY:
 - Standardized on native Form architecture.
 - Modernized the status header using a centered SDKStatPill group.
 - Replaced manual connector data list with native LabeledContent rows.
 - Modernized the Auth Fields section using monospaced typography and native SecureField toggle.
 - Standardized the error panel using a semantic red Label.
 - strictly preserved all BaseConnector authentication, Task logic, and credential binding.
 - Replaced manual disclosure groups with native Section headers/footers for help.
 - Standardized on prominent bordered styles for the "Connect" button.
 */

import SwiftUI

struct ConnectorAuthView<T: BaseConnector>: View {
    @ObservedObject var connector: T
    @Environment(\.dismiss) var dismiss
    @State private var credentials: [String: String] = [:]
    @State private var isAuthenticating = false
    @State private var error: String?
    @State private var showingSuccess = false
    @State private var revealedFields: Set<String> = []

    var body: some View {
        Form {
            Section {
                HStack(spacing: 0) {
                    SDKStatPill(label: "Status", value: connector.status.rawValue.capitalized, color: connector.status == .connected ? .sdkSuccess : .red)
                    SDKStatPill(label: "Fields", value: "\(credentials.values.filter { !$0.isEmpty }.count)/\(connector.authFields.count)", color: .orange)
                    SDKStatPill(label: "Type", value: connector.type.rawValue.capitalized, color: .blue)
                }
                .padding(.vertical, 8)
            }
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets())

            Section("Connector Data") {
                LabeledContent("Identifier", value: connector.id.uuidString).font(.caption2.monospaced())
                LabeledContent("Events", value: "\(connector.activityLog.count)")
                if let latest = connector.activityLog.first {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Latest Activity").font(.caption2.bold()).foregroundStyle(.secondary)
                        Text(latest.message).font(.caption2)
                        Text(latest.timestamp.formatted(.relative(presentation: .named))).font(.system(size: 8)).foregroundStyle(.tertiary)
                    }
                }
            }

            Section("Authentication Fields") {
                if connector.authFields.isEmpty {
                    Text("No authentication fields required.").font(.caption).foregroundStyle(.secondary)
                } else {
                    ForEach(connector.authFields, id: \.key) { field in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(field.label).font(.caption.bold()).foregroundStyle(.secondary)
                            HStack {
                                if field.isSecure && !revealedFields.contains(field.key) {
                                    SecureField(field.label, text: binding(for: field.key))
                                } else {
                                    TextField(field.label, text: binding(for: field.key))
                                }
                                if field.isSecure {
                                    Button {
                                        if revealedFields.contains(field.key) { revealedFields.remove(field.key) }
                                        else { revealedFields.insert(field.key) }
                                    } label: {
                                        Image(systemName: revealedFields.contains(field.key) ? "eye.slash" : "eye").font(.caption).foregroundStyle(.secondary)
                                    }
                                }
                            }
                            if (credentials[field.key] ?? "").isEmpty {
                                Text("Required").font(.system(size: 8, weight: .bold)).foregroundStyle(.orange)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
            }

            if let error = error {
                Section {
                    Label(error, systemImage: "exclamationmark.triangle.fill").font(.caption).foregroundStyle(.red)
                    Button("Dismiss Error") { self.error = nil }.font(.caption).foregroundStyle(.blue)
                }
            }

            Section {
                Button(action: authenticate) {
                    HStack {
                        Spacer()
                        if isAuthenticating {
                            ProgressView().padding(.trailing, 4)
                            Text("Connecting...")
                        } else {
                            Label("Connect Connector", systemImage: "link")
                        }
                        Spacer()
                    }
                    .frame(maxWidth: .infinity).bold()
                }
                .buttonStyle(.borderedProminent)
                .disabled(isAuthenticating || !allFieldsFilled)

                if !credentials.values.allSatisfy({ $0.isEmpty }) {
                    Button("Clear All Fields", role: .destructive) { credentials = [:]; error = nil }
                        .font(.caption).frame(maxWidth: .infinity)
                }
            }
            .listRowBackground(Color.clear)

            Section("Help") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("1. Fill in all required authentication fields.").font(.caption)
                    Text("2. Click 'Connect' to securely register your credentials.").font(.caption)
                    Text("3. Credentials are encrypted and sent only to the destination API.").font(.caption)
                }.foregroundStyle(.secondary).padding(.vertical, 4)
            }
        }
        .navigationTitle("Authenticate")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) { Button("Cancel") { dismiss() } }
        }
        .alert("Success", isPresented: $showingSuccess) {
            Button("OK") { dismiss() }
        } message: { Text("\(connector.name) has been authenticated successfully!") }
    }

    private var allFieldsFilled: Bool {
        connector.authFields.allSatisfy { field in !(credentials[field.key] ?? "").isEmpty }
    }

    private func binding(for key: String) -> Binding<String> {
        Binding(get: { credentials[key] ?? "" }, set: { credentials[key] = $0 })
    }

    private func authenticate() {
        isAuthenticating = true
        error = nil
        Task {
            do {
                try await connector.authenticate(credentials: credentials)
                await MainActor.run { isAuthenticating = false; showingSuccess = true }
            } catch {
                await MainActor.run { self.error = error.localizedDescription; isAuthenticating = false }
            }
        }
    }
}
