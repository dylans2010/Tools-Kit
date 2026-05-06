import SwiftUI

struct SDKConnectorsView: View {
    @StateObject private var manager = SDKConnectorManager.shared
    @State private var showingAddSheet = false

    var body: some View {
        List {
            ForEach(manager.connectors, id: \.id) { connector in
                NavigationLink(destination: ConnectorDetailView(connector: connector)) {
                    HStack {
                        Image(systemName: iconName(for: connector.type))
                            .foregroundStyle(.blue)
                            .frame(width: 30)

                        VStack(alignment: .leading) {
                            Text(connector.name).font(.headline)
                            Text(connector.type.rawValue.capitalized).font(.caption).foregroundStyle(.secondary)
                        }

                        Spacer()

                        StatusBadge(status: connector.status)
                    }
                }
            }
        }
        .navigationTitle("Connectors")
        .toolbar {
            Button(action: { showingAddSheet = true }) {
                Image(systemName: "plus")
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            AddConnectorView()
        }
    }

    private func iconName(for type: ConnectorType) -> String {
        switch type {
        case .gmail: return "envelope.fill"
        case .webhook: return "arrow.up.right.circle.fill"
        case .github: return "cat.fill"
        case .localFileSystem: return "folder.fill"
        case .calendar: return "calendar"
        }
    }
}

struct StatusBadge: View {
    let status: ConnectorStatus
    var body: some View {
        Text(status.rawValue.uppercased())
            .font(.system(size: 8, weight: .bold))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.2))
            .foregroundStyle(color)
            .cornerRadius(4)
    }

    var color: Color {
        switch status {
        case .connected: return .green
        case .connecting: return .orange
        case .disconnected: return .gray
        case .error: return .red
        }
    }
}

struct AddConnectorView: View {
    @Environment(\.dismiss) var dismiss
    var body: some View {
        NavigationStack {
            List(ConnectorType.allCases, id: \.self) { type in
                Button(type.rawValue.capitalized) {
                    let new: any BaseConnector
                    switch type {
                    case .gmail: new = GmailConnector()
                    case .webhook: new = WebhookConnector()
                    case .github: new = GitHubConnector()
                    case .localFileSystem: new = LocalFileConnector()
                    case .calendar: new = CalendarConnector()
                    }
                    SDKConnectorManager.shared.register(new)
                    dismiss()
                }
            }
            .navigationTitle("Add Connector")
            .toolbar {
                Button("Cancel") { dismiss() }
            }
        }
    }
}
