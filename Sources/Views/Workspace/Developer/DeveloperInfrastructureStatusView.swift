import SwiftUI

struct DeveloperInfrastructureStatusView: View {
    @ObservedObject var infraService = InfrastructureService.shared
    @State private var nodes: [InfrastructureNode] = []
    @State private var isRefreshing = false

    private var averageCPUUsage: Int {
        guard !nodes.isEmpty else { return 0 }
        let totalUsage = nodes.map { $0.cpuUsage }.reduce(0, +)
        return Int(totalUsage / Double(nodes.count) * 100)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                statusHeader

                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        SectionHeader(title: "Compute Clusters", subtitle: nil, icon: "cpu")
                        Spacer()
                        if isRefreshing { ProgressView().controlSize(.small) }
                    }

                    if nodes.isEmpty {
                        EmptyStateView(icon: "server.rack", title: "No Nodes Detected", message: "Initialize your infrastructure cluster to start monitoring compute resources.")
                    } else {
                        ForEach(nodes) { node in
                            nodeRow(node)
                        }
                    }
                }
                .padding()

                operationalInsights
            }
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("Infrastructure")
        .refreshable { refreshInfra() }
        .onAppear { refreshInfra() }
    }

    private var statusHeader: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("System Status").font(.headline)
                    Text("All systems operational").font(.caption).foregroundStyle(.green)
                }
                Spacer()
                Circle().fill(.green).frame(width: 12, height: 12)
            }

            HStack(spacing: 24) {
                infraMetric(label: "CPU Usage", value: "\(averageCPUUsage)%", color: .blue)
                infraMetric(label: "Memory", value: "2.4 GB", color: .purple)
                infraMetric(label: "Storage", value: "84%", color: .orange)
            }
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.primary.opacity(0.05), lineWidth: 1))
        .padding()
    }

    private func infraMetric(label: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.system(size: 9, weight: .bold)).foregroundStyle(.secondary).textCase(.uppercase)
            Text(value).font(.title3.bold()).foregroundStyle(color)
        }
    }

    private func nodeRow(_ node: InfrastructureNode) -> some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 8).fill(node.status == .healthy ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
                Image(systemName: "server.rack").font(.system(size: 14)).foregroundStyle(node.status == .healthy ? .green : .red)
            }
            .frame(width: 36, height: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text(node.name).font(.subheadline.bold())
                Text(node.type).font(.system(size: 10, design: .monospaced)).foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(Int(node.cpuUsage * 100))% LOAD").font(.system(size: 8, weight: .black))
                Text(node.region).font(.system(size: 8)).foregroundStyle(.tertiary)
            }
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.primary.opacity(0.05), lineWidth: 1))
    }

    private var operationalInsights: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Traffic Insights", subtitle: nil, icon: "chart.bar.fill")

            HStack(alignment: .bottom, spacing: 4) {
                let metrics = DeveloperPersistentStore.shared.performanceMetrics.prefix(20)
                if metrics.isEmpty {
                    Text("No traffic data available.").font(.caption).foregroundStyle(.secondary)
                } else {
                    ForEach(Array(metrics.enumerated()), id: \.offset) { _, metric in
                        RoundedRectangle(cornerRadius: 1)
                            .fill(Color.blue.opacity(0.4))
                            .frame(height: CGFloat(max(5, metric.value)))
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .frame(height: 40)

            Text("Edge nodes are experiencing normal throughput. Global load balancing is active.")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }

    private func refreshInfra() {
        isRefreshing = true
        Task {
            let fetchedNodes = try? await infraService.fetchNodes()
            await MainActor.run {
                self.nodes = fetchedNodes ?? []
                self.isRefreshing = false
            }
        }
    }
}
