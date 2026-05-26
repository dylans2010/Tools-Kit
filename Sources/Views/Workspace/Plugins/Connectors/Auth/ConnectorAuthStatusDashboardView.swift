import SwiftUI

struct ConnectorAuthStatusDashboardView: View {
    @StateObject private var connectorManager = SDKConnectorManager.shared

    var body: some View {
        List {
            Section("Global Connection Health") {
                let connectedCount = connectorManager.connectors.filter(\.isConnected).count
                let totalCount = connectorManager.connectors.count

                VStack(spacing: 12) {
                    ProgressView(value: Double(connectedCount), total: Double(max(1, totalCount)))
                        .tint(connectedCount == totalCount ? .green : .orange)

                    HStack {
                        Text("\(connectedCount) Connected")
                            .font(.headline)
                        Spacer()
                        Text("\(totalCount - connectedCount) Action Required")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 8)
            }

            Section("Detailed Auth Status") {
                if connectorManager.connectors.isEmpty {
                    Text("No connectors registered").foregroundStyle(.secondary)
                } else {
                    ForEach(connectorManager.connectors, id: \.id) { connector in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(connector.name).font(.subheadline.bold())
                                Spacer()
                                StatusBadge(isConnected: connector.isConnected)
                            }

                            if connector.isConnected {
                                Text("Token valid for another 12 hours")
                                    .font(.caption2)
                                    .foregroundStyle(.green)
                            } else {
                                Text("Last attempt failed: Invalid Credentials")
                                    .font(.caption2)
                                    .foregroundStyle(.red)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .navigationTitle("Auth Dashboard")
    }
}

private struct StatusBadge: View {
    let isConnected: Bool

    var body: some View {
        Text(isConnected ? "ACTIVE" : "EXPIRED")
            .font(.system(size: 8, weight: .black))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(isConnected ? Color.green.opacity(0.2) : Color.red.opacity(0.2), in: Capsule())
            .foregroundStyle(isConnected ? .green : .red)
    }
}
