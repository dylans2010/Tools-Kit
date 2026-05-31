import SwiftUI

struct DeveloperInfrastructureStatusView: View {
    @ObservedObject var infrastructureService = InfrastructureService.shared
    @State private var showingAddNode = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                globalHealthSummary

                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Active Nodes").font(.headline)
                        Spacer()
                        Button { requestNewNode() } label: {
                             Image(systemName: "plus.circle.fill").font(.title3)
                        }
                    }

                    if infrastructureService.nodes.isEmpty {
                        EmptyStateView(icon: "server.rack", title: "No Nodes", message: "Connect your infrastructure to monitor health and resource utilization.")
                    } else {
                        ForEach(infrastructureService.nodes) { node in
                            nodeCard(node)
                        }
                    }
                }
            }
            .padding()
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("Infrastructure")
    }

    private var globalHealthSummary: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("System Status").font(.headline)
                    Text("All clusters reporting healthy").font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "waveform.path.ecg").foregroundStyle(.green).font(.title2)
            }

            HStack(spacing: 20) {
                metricBox(label: "Uptime", value: "99.99%", color: .green)
                metricBox(label: "Avg CPU", value: "24%", color: .blue)
                metricBox(label: "Avg Memory", value: "4.2GB", color: .purple)
            }
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func metricBox(label: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value).font(.title3.bold()).foregroundStyle(color)
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func nodeCard(_ node: InfrastructureNode) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(node.name).font(.subheadline.bold())
                    Text(node.region).font(.system(size: 8, weight: .bold)).foregroundStyle(.secondary)
                }
                Spacer()
                statusBadge(node.status)
            }

            VStack(spacing: 8) {
                resourceBar(label: "CPU", value: node.cpuUsage, color: .blue)
                resourceBar(label: "Memory", value: node.memoryUsage, color: .purple)
            }

            HStack {
                Text(node.ipAddress).font(.system(size: 8, design: .monospaced)).foregroundStyle(.tertiary)
                Spacer()
                Text("v\(node.version)").font(.system(size: 8)).foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.primary.opacity(0.05), lineWidth: 1))
    }

    private func resourceBar(label: String, value: Double, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label).font(.system(size: 8, weight: .bold)).foregroundStyle(.secondary)
                Spacer()
                Text("\(Int(value * 100))%").font(.system(size: 8)).foregroundStyle(.secondary)
            }
            ProgressView(value: value)
                .progressViewStyle(.linear)
                .tint(value > 0.8 ? .red : color)
        }
    }

    private func statusBadge(_ status: NodeStatus) -> some View {
        Text(status.rawValue.uppercased()).font(.system(size: 8, weight: .bold))
            .padding(.horizontal, 6).padding(.vertical, 2)
            .background(statusColor(status).opacity(0.1), in: Capsule())
            .foregroundStyle(statusColor(status))
    }

    private func statusColor(_ status: NodeStatus) -> Color {
        switch status {
        case .online: return .green
        case .offline: return .red
        case .maintenance: return .orange
        case .provisioning: return .blue
        }
    }

    private func requestNewNode() {
        // Logic to request a new infrastructure node
        showingAddNode = true
    }
}
