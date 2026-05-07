import SwiftUI

struct ConnectorsMainView: View {
    @StateObject private var manager = ConnectorManager.shared
    @State private var showingBuilder = false
    @State private var showingDocs = false

    var body: some View {
        let connectors: [ConnectorDefinition] = manager.connectors
        let activeCount: Int = connectors.filter { $0.status == .active }.count
        let errorCount: Int = connectors.filter { $0.status == .error }.count

        return List {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Connectors Platform")
                        .font(.headline)
                    Text("Advanced integration modules for external APIs, secure authentication, and multi-step workflows.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    HStack(spacing: 16) {
                        statView(label: "Connectors", value: "\(connectors.count)", color: .blue)
                        statView(label: "Active", value: "\(activeCount)", color: .green)
                        statView(label: "Errors", value: "\(errorCount)", color: .red)
                    }
                    .padding(.top, 4)
                }
                .padding(.vertical, 8)
            }

            Section("Your Connectors") {
                if connectors.isEmpty {
                    VStack(alignment: .center, spacing: 12) {
                        Image(systemName: "puzzlepiece.extension")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)
                        Text("No Connectors Created")
                            .font(.headline)
                        Text("Build your first integration engine to connect external services.")
                            .font(.caption)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)

                        Button("Create Connector") {
                            showingBuilder = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                } else {
                    ForEach(connectors) { connector in
                        NavigationLink(destination: ConnectorDetailView(connector: connector)) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(connector.name)
                                        .font(.headline)
                                    Text(connector.identifier)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                connectorStatusPill(status: connector.status)
                            }
                        }
                    }
                }
            }

            Section("Platform Tools") {
                NavigationLink(destination: ConnectorLogsView()) {
                    Label("Global Execution Logs", systemImage: "list.bullet.rectangle")
                }
                NavigationLink(destination: ConnectorSecurityView()) {
                    Label("Security & Scopes", systemImage: "shield.auth.gradient")
                }
                Button {
                    showingDocs = true
                } label: {
                    Label("Connectors Documentation", systemImage: "book.closed")
                }
            }
        }
        .navigationTitle("Connectors")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingBuilder = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingBuilder) {
            NavigationView {
                ConnectorBuilderView()
            }
        }
        .sheet(isPresented: $showingDocs) {
            ConnectorDocumentationView()
        }
    }

    private func statView(label: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.title2.bold())
                .foregroundColor(color)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
                .textCase(.uppercase)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func connectorStatusPill(status: ConnectorDefinition.ConnectorStatus) -> some View {
        Text(status.rawValue.capitalized)
            .font(.system(size: 10, weight: .bold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(statusColor(status).opacity(0.15))
            .foregroundColor(statusColor(status))
            .clipShape(Capsule())
    }

    private func statusColor(_ status: ConnectorDefinition.ConnectorStatus) -> Color {
        switch status {
        case .active: return .green
        case .inactive: return .secondary
        case .error: return .red
        case .connecting: return .blue
        }
    }
}

// MARK: - Connector Documentation

struct ConnectorDocumentationView: View {
    @Environment(\.dismiss) var dismiss
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Group {
                        Text("Connector Platform Documentation")
                            .font(.title.bold())

                        Text("Architecture")
                            .font(.headline)
                        Text("Connectors are dedicated integration engines that bridge ToolsKit with external REST APIs. They support complex authentication, schema mapping, and multi-step workflow pipelines.")
                            .foregroundColor(.secondary)
                    }

                    Group {
                        Text("How to connect APIs")
                            .font(.headline)
                        Text("1. Define endpoints with path, method, and headers.\n2. Configure the Auth Strategy (API Key, Bearer, or OAuth2).\n3. Map response fields to workspace models using the Schema Builder.")
                            .foregroundColor(.secondary)
                    }

                    Group {
                        Text("Authentication Setup")
                            .font(.headline)
                        Text("Credentials are encrypted and stored securely. OAuth2 flows handle token exchange and automatic background refreshing.")
                            .foregroundColor(.secondary)
                    }

                    Group {
                        Text("Building Flows")
                            .font(.headline)
                        Text("Use the visual Flow Designer to create Trigger-Condition-Action pipelines. Connectors can be triggered by workspace events or external webhooks.")
                            .foregroundColor(.secondary)
                    }

                    Group {
                        Text("Example Flow")
                            .font(.subheadline.bold())
                        Text("Trigger: note.created\nCondition: content.includes('ticket')\nAction: POST https://api.jira.com/issue")
                            .font(.system(.caption, design: .monospaced))
                            .padding()
                            .background(Color.green.opacity(0.05))
                            .cornerRadius(8)
                    }
                }
                .padding()
            }
            .navigationTitle("Documentation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
