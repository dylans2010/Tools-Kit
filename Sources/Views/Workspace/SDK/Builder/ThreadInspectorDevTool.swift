import SwiftUI

struct ThreadInspectorDevTool: DevTool {
    let id = "thread-inspector"
    let name = "Thread Inspector"
    let category = DevToolCategory.diagnostics
    let icon = "line.3.horizontal"
    let description = "Monitor active threads and queues"

    func render() -> some View {
        ThreadInspectorView()
    }
}

struct ThreadInspectorView: View {
    @StateObject private var viewModel = ThreadInspectorViewModel()

    var body: some View {
        List {
            Section("Resource Allocation") {
                HStack(spacing: 20) {
                    ThreadMetric(label: "Total Count", value: "24", color: .blue)
                    ThreadMetric(label: "High Priority", value: "3", color: .red)
                    ThreadMetric(label: "Idle", value: "12", color: .green)
                }
                .padding(.vertical, 8)
            }

            Section("Execution Contexts") {
                ForEach(viewModel.threads) { thread in
                    HStack(spacing: 12) {
                        Circle()
                            .fill(thread.priority == "High" ? .red : .blue)
                            .frame(width: 8, height: 8)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(thread.name).font(.subheadline.bold())
                            Text(thread.details).font(.system(size: 9)).foregroundStyle(.secondary)
                        }

                        Spacer()

                        Text(thread.priority)
                            .font(.system(size: 8, weight: .black))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .foregroundStyle(.white)
                            .background(thread.priority == "High" ? Color.red : Color.blue, in: Capsule())
                    }
                    .padding(.vertical, 2)
                }
            }

            Section("Quality of Service (QoS)") {
                QoSRow(label: "User Interactive", count: 2, color: .red)
                QoSRow(label: "User Initiated", count: 4, color: .orange)
                QoSRow(label: "Utility", count: 8, color: .blue)
                QoSRow(label: "Background", count: 10, color: .gray)
            }
        }
        .navigationTitle("Threads")
        .refreshable { viewModel.refresh() }
        .onAppear { viewModel.refresh() }
    }
}

struct ThreadMetric: View {
    let label: String
    let value: String
    let color: Color
    var body: some View {
        VStack(spacing: 4) {
            Text(value).font(.title3.bold().monospacedDigit()).foregroundStyle(color)
            Text(label).font(.system(size: 8, weight: .black)).foregroundStyle(.secondary).textCase(.uppercase)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(color.opacity(0.05), in: RoundedRectangle(cornerRadius: 10))
    }
}

struct QoSRow: View {
    let label: String
    let count: Int
    let color: Color
    var body: some View {
        HStack {
            Text(label).font(.caption)
            Spacer()
            Text("\(count)").font(.caption.monospaced()).foregroundStyle(.secondary)
            Capsule()
                .fill(color)
                .frame(width: CGFloat(count) * 10, height: 4)
        }
    }
}

struct ThreadInfo: Identifiable {
    let id = UUID()
    let name: String
    let details: String
    let priority: String
}

class ThreadInspectorViewModel: ObservableObject {
    @Published var threads: [ThreadInfo] = []

    func refresh() {
        threads = [
            ThreadInfo(name: "Main Thread", details: "Running UI loop", priority: "High"),
            ThreadInfo(name: "com.apple.root.user-interactive", details: "Executing task", priority: "High"),
            ThreadInfo(name: "com.toolskit.sdk.logstore", details: "Background persistence", priority: "Background")
        ]
    }
}

#Preview {
    ThreadInspectorView()
}
