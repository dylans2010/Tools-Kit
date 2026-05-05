import SwiftUI

struct ConnectorsMainView: View {
    @StateObject private var manager = ConnectorManager.shared

    var body: some View {
        List {
            Section {
                HStack(spacing: 20) {
                    ConnectorStatPill(label: "Active", count: manager.connectors.filter(\.isEnabled).count, color: .green)
                    ConnectorStatPill(label: "Inactive", count: manager.connectors.filter { !$0.isEnabled }.count, color: .secondary)
                }
                .padding(.vertical, 8)
            }

            Section("Connectors") {
                if manager.connectors.isEmpty {
                    Text("No connectors configured.")
                        .foregroundColor(.secondary)
                        .font(.subheadline)
                } else {
                    ForEach(manager.connectors) { connector in
                        NavigationLink(destination: ConnectorDetailView(connector: connector)) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(connector.name).font(.headline)
                                    Text(connector.identifier).font(.caption).foregroundColor(.secondary)
                                }
                                Spacer()
                                StatusPill(status: connector.status)
                            }
                        }
                    }
                }
            }

            Section("Management") {
                NavigationLink(destination: ConnectorBuilderView()) {
                    Label("Create Connector", systemImage: "plus.circle")
                }
                NavigationLink(destination: ConnectorLogsView()) {
                    Label("View Logs", systemImage: "terminal")
                }
                NavigationLink(destination: connectorDocsSection) {
                    Label("Documentation", systemImage: "book")
                }
            }
        }
        .navigationTitle("Connectors")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                NavigationLink(destination: ConnectorBuilderView()) {
                    Image(systemName: "plus")
                }
            }
        }
    }
}

struct ConnectorStatPill: View {
    let label: String
    let count: Int
    let color: Color

    var body: some View {
        VStack(alignment: .leading) {
            Text("\(count)").font(.title2.bold()).foregroundColor(color)
            Text(label).font(.caption).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct StatusPill: View {
    let status: ConnectorStatus

    var body: some View {
        Text(status.rawValue.capitalized)
            .font(.system(size: 10, weight: .bold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.1))
            .foregroundColor(color)
            .clipShape(Capsule())
    }

    private var connectorDocsSection: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Connector Development Guide").font(.title.bold())

                Group {
                    Text("Connecting APIs").font(.headline)
                    Text("Define Base URL and Endpoints. Configure Method, Path, and Body schemas.").font(.subheadline)
                }

                Group {
                    Text("Authentication").font(.headline)
                    Text("Connectors support API Key, Bearer Token, and OAuth2. Tokens are stored securely.").font(.subheadline)
                }

                Group {
                    Text("Building Flows").font(.headline)
                    Text("Create multi-step pipelines triggered by Webhooks, Schedules, or Workspace Events.").font(.subheadline)
                }

                Group {
                    Text("Data Mapping").font(.headline)
                    Text("Use the Schema Builder to transform external JSON into ToolsKit models.").font(.subheadline)
                }
            }
            .padding()
        }
        .navigationTitle("Connector Guide")
    }

    private var color: Color {
        switch status {
        case .active: return .green
        case .disconnected: return .secondary
        case .error: return .red
        case .degraded: return .orange
        }
    }
}
