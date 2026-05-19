import SwiftUI

private class _DTSDK: ObservableObject {
    static let shared = _DTSDK()
    @Published var isInitialized: Bool = false
    @Published var version: String = "unknown"
    private init() {}
}

struct SDKRuntimeStateDevTool: DevTool {
    let id = "sdk-runtime-state"
    let name = "Runtime State"
    let category = DevToolCategory.debugging
    let icon = "brain.head.profile"
    let description = "Monitor SDK internal state"

    func render() -> some View {
        SDKRuntimeStateView()
    }
}

struct SDKRuntimeStateView: View {
    @StateObject private var sdk = _DTSDK.shared

    var body: some View {
        List {
            Section("Environment Health") {
                VStack(spacing: 24) {
                    ZStack {
                        Circle()
                            .stroke(Color.gray.opacity(0.1), lineWidth: 10)
                        Circle()
                            .trim(from: 0, to: 0.95)
                            .stroke(Color.green.gradient, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                            .rotationEffect(.degrees(-90))

                        VStack(spacing: 0) {
                            Text("95").font(.system(size: 44, weight: .black, design: .rounded))
                            Text("HEALTH").font(.system(size: 10, weight: .bold)).foregroundStyle(.secondary)
                        }
                    }
                    .frame(width: 140, height: 140)
                    .padding(.top, 10)

                    HStack(spacing: 20) {
                        RuntimeMetricItem(label: "State", value: sdk.isInitialized ? "INIT" : "IDLE", color: .blue)
                        RuntimeMetricItem(label: "Version", value: "v2.4.1", color: .orange)
                    }
                }
                .padding(.vertical, 12)
            }

            Section("Subsystem Heartbeats") {
                SubsystemRow(name: "Policy Engine", status: "Active", isHealthy: true)
                SubsystemRow(name: "Audit Logger", status: "Running", isHealthy: true)
                SubsystemRow(name: "Data Engine", status: "Syncing", isHealthy: true)
                SubsystemRow(name: "Event Bus", status: "Active", isHealthy: true)
                SubsystemRow(name: "Connector Hub", status: "Standby", isHealthy: true)
            }

            Section("Performance Milestones") {
                LabeledContent("Boot Latency", value: "142ms")
                LabeledContent("Cache Hit Rate", value: "89%")
                LabeledContent("Queue Pressure", value: "Low")
            }

            Section {
                Button("Force System Restart") { /* Logic */ }
                    .foregroundStyle(.red)
                Button("Run Full Diagnostics") { /* Logic */ }
            }
        }
        .navigationTitle("Runtime Status")
    }
}

struct RuntimeMetricItem: View {
    let label: String
    let value: String
    let color: Color
    var body: some View {
        VStack(spacing: 4) {
            Text(value).font(.headline.bold())
            Text(label).font(.system(size: 8, weight: .black)).foregroundStyle(.secondary).textCase(.uppercase)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(color.opacity(0.05), in: RoundedRectangle(cornerRadius: 10))
    }
}

struct SubsystemRow: View {
    let name: String
    let status: String
    let isHealthy: Bool
    var body: some View {
        HStack {
            Circle()
                .fill(isHealthy ? Color.green : Color.red)
                .frame(width: 8, height: 8)
            Text(name).font(.subheadline)
            Spacer()
            Text(status)
                .font(.system(size: 8, weight: .black))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.gray.opacity(0.1), in: Capsule())
        }
    }
}

#Preview {
    SDKRuntimeStateView()
}
