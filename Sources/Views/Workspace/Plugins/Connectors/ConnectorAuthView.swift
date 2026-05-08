import SwiftUI

struct ConnectorAuthView<T: BaseConnector>: View {
    @ObservedObject var connector: T
    @Environment(\.dismiss) var dismiss
    @State private var credentials: [String: String] = [:]
    @State private var isAuthenticating = false
    @State private var error: String?
    @State private var showingSuccess = false
    @State private var showingHelp = false
    @State private var revealedFields: Set<String> = []

    var filledFieldsCount: Int {
        credentials.values.filter { !$0.isEmpty }.count
    }

    var allFieldsFilled: Bool {
        connector.authFields.allSatisfy { field in
            !(credentials[field.key] ?? "").isEmpty
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                // MARK: - Status
                Section {
                    HStack(spacing: 16) {
                        VStack(spacing: 2) {
                            Text(connector.status.rawValue.capitalized)
                                .font(.title3.bold())
                                .foregroundColor(connector.status == .connected ? .green : .red)
                            Text("Status")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)

                        VStack(spacing: 2) {
                            Text("\(filledFieldsCount)/\(connector.authFields.count)")
                                .font(.title3.bold())
                                .foregroundColor(allFieldsFilled ? .green : .orange)
                            Text("Fields")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)

                        VStack(spacing: 2) {
                            Text(connector.type.rawValue.capitalized)
                                .font(.title3.bold())
                                .foregroundColor(.blue)
                            Text("Type")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }

                Section("Connector Data") {
                    LabeledContent("Connector ID", value: connector.id.uuidString)
                    LabeledContent("Auth Fields", value: "\(connector.authFields.count)")
                    LabeledContent("Activity Events", value: "\(connector.activityLog.count)")
                    if let latest = connector.activityLog.first {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Latest activity")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(latest.message)
                                .font(.caption)
                            Text(latest.timestamp.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                // MARK: - Auth Fields
                Section("Authentication Fields") {
                    if connector.authFields.isEmpty {
                        Text("No authentication fields required for this connector.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(connector.authFields, id: \.key) { field in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(field.label)
                                    .font(.caption)
                                    .foregroundColor(.secondary)

                                if field.isSecure && !revealedFields.contains(field.key) {
                                    HStack {
                                        SecureField(field.label, text: binding(for: field.key))
                                        Button {
                                            revealedFields.insert(field.key)
                                        } label: {
                                            Image(systemName: "eye")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                } else {
                                    HStack {
                                        TextField(field.label, text: binding(for: field.key))
                                        if field.isSecure {
                                            Button {
                                                revealedFields.remove(field.key)
                                            } label: {
                                                Image(systemName: "eye.slash")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                    }
                                }

                                if (credentials[field.key] ?? "").isEmpty {
                                    Text("Required")
                                        .font(.caption2)
                                        .foregroundColor(.orange)
                                }
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }

                // MARK: - Error
                if let error = error {
                    Section("Error") {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                            Text(error)
                                .foregroundStyle(.red)
                                .font(.caption)
                        }

                        Button {
                            self.error = nil
                        } label: {
                            Text("Dismiss Error")
                                .font(.caption)
                        }
                    }
                }

                // MARK: - Actions
                Section {
                    Button {
                        authenticate()
                    } label: {
                        HStack {
                            Spacer()
                            if isAuthenticating {
                                ProgressView()
                                    .progressViewStyle(.circular)
                                Text("Connecting...")
                                    .font(.subheadline)
                            } else {
                                Image(systemName: "link")
                                Text("Connect")
                                    .bold()
                            }
                            Spacer()
                        }
                    }
                    .disabled(isAuthenticating || !allFieldsFilled)

                    if !credentials.values.allSatisfy({ $0.isEmpty }) {
                        Button(role: .destructive) {
                            credentials = [:]
                            error = nil
                        } label: {
                            Label("Clear All Fields", systemImage: "xmark.circle")
                                .font(.caption)
                        }
                    }
                }

                if !connector.activityLog.isEmpty {
                    Section("Authentication Activity") {
                        ForEach(connector.activityLog.prefix(5)) { event in
                            VStack(alignment: .leading, spacing: 3) {
                                Text(event.message).font(.caption)
                                Text(event.timestamp.formatted(date: .abbreviated, time: .shortened))
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                // MARK: - Help
                Section("Help") {
                    DisclosureGroup("Authentication Guide") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("1. Fill in all required authentication fields above.")
                                .font(.caption)
                            Text("2. Click 'Connect' to authenticate with the service.")
                                .font(.caption)
                            Text("3. If authentication succeeds, the connector status will update to 'Connected'.")
                                .font(.caption)
                            Text("4. If you receive an error, verify your credentials and try again.")
                                .font(.caption)
                        }
                        .foregroundColor(.secondary)
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Authenticate \(connector.name)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .alert("Connected!", isPresented: $showingSuccess) {
                Button("OK") { dismiss() }
            } message: {
                Text("\(connector.name) has been authenticated successfully.")
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
                    showingSuccess = true
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
