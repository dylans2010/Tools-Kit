import SwiftUI

struct ConnectorDetailView: View {
    @State var connector: ConnectorDefinition
    @StateObject private var manager = ConnectorManager.shared
    @State private var showingTestConsole = false
    @State private var isRunning = false

    var body: some View {
        List {
            headerSection

            Section("Status & Metrics") {
                HStack {
                    Label("Current Status", systemImage: "circle.fill")
                        .foregroundColor(statusColor(connector.status))
                    Spacer()
                    Text(connector.status.rawValue.capitalized)
                        .bold()
                }

                HStack {
                    Text("Last Executed")
                    Spacer()
                    Text(connector.metadata.lastExecutedAt?.formatted() ?? "Never")
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text("Total Executions")
                    Spacer()
                    Text("\(connector.metadata.executionCount)")
                }
            }

            Section("Configuration") {
                NavigationLink(destination: ConnectorBuilderView(connector: connector)) {
                    Label("Identity & Basic Info", systemImage: "info.circle")
                }
                NavigationLink(destination: ConnectorAuthView(connector: connector)) {
                    Label("Authentication Setup", systemImage: "lock.shield")
                }
                NavigationLink(destination: ConnectorSchemaBuilderView(connector: connector)) {
                    Label("Data Schema & Mapping", systemImage: "tablecells")
                }
                NavigationLink(destination: ConnectorFlowBuilderView(connector: connector)) {
                    Label("Workflow Pipeline", systemImage: "arrow.triangle.pull")
                }
                NavigationLink(destination: ConnectorVersioningView(connector: connector)) {
                    Label("Versioning & Releases", systemImage: "tag")
                }
            }

            Section("Maintenance") {
                NavigationLink(destination: ConnectorLogsView(connectorID: connector.id)) {
                    Label("Execution Logs", systemImage: "doc.text.magnifyingglass")
                }
                NavigationLink(destination: ConnectorSecurityView(connector: connector)) {
                    Label("Security Settings", systemImage: "shield.lefthalf.filled")
                }
            }

            Section {
                Button(role: .destructive) {
                    manager.deleteConnector(id: connector.id)
                } label: {
                    Label("Delete Connector", systemImage: "trash")
                }
            }
        }
        .navigationTitle(connector.name)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button {
                    showingTestConsole = true
                } label: {
                    Image(systemName: "play.circle")
                }

                Button {
                    Task {
                        isRunning = true
                        await ConnectorRuntime.shared.run(connector: connector)
                        isRunning = false
                        // Refresh connector state from manager
                        if let updated = manager.connectors.first(where: { $0.id == connector.id }) {
                            connector = updated
                        }
                    }
                } label: {
                    if isRunning {
                        ProgressView()
                    } else {
                        Text("Run Now")
                    }
                }
                .disabled(isRunning)
            }
        }
        .sheet(isPresented: $showingTestConsole) {
            NavigationView {
                ConnectorTestConsoleView(connector: connector)
            }
        }
    }

    private var headerSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                Text(connector.identifier)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.secondary)

                Text(connector.description)
                    .font(.subheadline)

                HStack {
                    Text("v\(connector.version)")
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .clipShape(Capsule())

                    Spacer()

                    Text("Created \(connector.createdAt.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 4)
        }
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
