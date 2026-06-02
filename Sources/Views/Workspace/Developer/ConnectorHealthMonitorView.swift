import SwiftUI

struct ConnectorHealthMonitorView: View {
    @ObservedObject var store = DeveloperPersistentStore.shared

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                globalStats

                VStack(alignment: .leading, spacing: 16) {
                    Text("Service Status")
                        .font(.headline)
                        .padding(.horizontal)

                    if store.connectors.isEmpty {
                        Text("No connectors to monitor.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else {
                        ForEach(store.connectors) { connector in
                            let health = store.connectorHealth.first(where: { $0.connectorID == connector.id }) ?? ConnectorHealth(connectorID: connector.id)
                            HealthRow(name: connector.name, health: health)
                        }
                    }
                }
                .padding(.vertical)
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationTitle("Health Monitor")
        .background(Color(uiColor: .systemGroupedBackground))
        .onAppear(perform: refreshHealth)
    }

    private var globalStats: some View {
        HStack(spacing: 12) {
            VStack {
                Text("UPTIME").font(.caption2.bold()).foregroundStyle(.secondary)
                Text("99.98%").font(.title2.bold()).foregroundStyle(.green)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack {
                Text("ERRORS").font(.caption2.bold()).foregroundStyle(.secondary)
                Text("12").font(.title2.bold()).foregroundStyle(.red)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding(.horizontal)
    }

    private func refreshHealth() {
        if store.connectorHealth.isEmpty && !store.connectors.isEmpty {
            let mock = store.connectors.map { connector in
                ConnectorHealth(
                    connectorID: connector.id,
                    status: .healthy,
                    uptimePercentage: Double.random(in: 95.0...100.0),
                    lastCheck: Date(),
                    errorCount: Int.random(in: 0...2)
                )
            }
            store.saveConnectorHealth(mock)
        }
    }
}

private struct HealthRow: View {
    let name: String
    let health: ConnectorHealth

    var body: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(statusColor)
                .frame(width: 10, height: 10)

            VStack(alignment: .leading, spacing: 2) {
                Text(name).font(.subheadline.bold())
                Text("Last checked: \(health.lastCheck, style: .time)").font(.caption2).foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(String(format: "%.2f%%", health.uptimePercentage))
                    .font(.system(.caption, design: .monospaced))
                    .bold()
                Text("\(health.errorCount) errors")
                    .font(.system(size: 8))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal)
    }

    private var statusColor: Color {
        switch health.status {
        case .healthy: return .green
        case .degraded: return .orange
        case .down: return .red
        case .unknown: return .gray
        }
    }
}
