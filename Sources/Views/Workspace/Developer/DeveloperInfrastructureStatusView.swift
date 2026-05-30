import SwiftUI

struct DeveloperInfrastructureStatusView: View {
    @ObservedObject var infraService = InfrastructureService.shared

    var body: some View {
        List {
            Section("Infrastructure Nodes") {
                if infraService.nodes.isEmpty {
                    EmptyStateView(icon: "server.rack", title: "No Nodes", message: "Monitor your cloud infrastructure and regional service health.")
                } else {
                    ForEach(infraService.nodes) { node in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(node.name).font(.subheadline.bold())
                                Spacer()
                                Text(node.status.rawValue).font(.system(size: 8, weight: .bold))
                                    .padding(.horizontal, 6).padding(.vertical, 2)
                                    .background(statusColor(node.status).opacity(0.1))
                                    .foregroundStyle(statusColor(node.status))
                                    .clipShape(Capsule())
                            }
                            HStack {
                                Text("\(node.type) • \(node.region)").font(.caption).foregroundStyle(.secondary)
                                Spacer()
                                Text("CPU: \(Int(node.cpuUsage))%").font(.system(size: 8, design: .monospaced))
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Infrastructure Status")
    }

    private func statusColor(_ status: NodeStatus) -> Color {
        switch status {
        case .healthy: return .green
        case .degraded: return .orange
        case .down: return .red
        }
    }
}
