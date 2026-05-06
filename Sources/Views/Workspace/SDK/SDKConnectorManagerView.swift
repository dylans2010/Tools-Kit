import SwiftUI

struct SDKConnectorManagerView: View {
    @StateObject private var connectorManager = SDKConnectorManager.shared

    var body: some View {
        List(connectorManager.connectors, id: \.id) { connector in
            HStack {
                VStack(alignment: .leading) {
                    Text(connector.name).font(.headline)
                    Text(connector.type.rawValue).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                statusBadge(connector.status)
            }
        }
        .navigationTitle("Connectors")
        .toolbar {
            Button(action: {}) {
                Image(systemName: "plus")
            }
        }
    }

    @ViewBuilder
    private func statusBadge(_ status: ConnectorStatus) -> some View {
        Text(status.rawValue.capitalized)
            .font(.caption2).bold()
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(statusColor(status).opacity(0.2), in: Capsule())
            .foregroundStyle(statusColor(status))
    }

    private func statusColor(_ status: ConnectorStatus) -> Color {
        switch status {
        case .connected: return .green
        case .disconnected: return .gray
        case .error: return .red
        case .connecting: return .yellow
        }
    }
}
