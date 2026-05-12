import SwiftUI

struct AgenticUIHomeView: View {
    @StateObject private var orchestrator = AgenticCoreOrchestrator.shared
    @StateObject private var traceStore = AgenticExecutionTraceStore.shared

    var body: some View {
        List {
            Section("Recent Actions") {
                if traceStore.traces.isEmpty {
                    ContentUnavailableView("No Recent Actions", systemImage: "bolt.horizontal", description: Text("Tool executions will appear here in real time."))
                } else {
                    ForEach(traceStore.traces.reversed()) { trace in
                        AgenticTraceRow(trace: trace)
                    }
                }
            }

            Section {
                NavigationLink(destination: AgenticUIChatView()) {
                    Label("Agentic Chat", systemImage: "sparkles")
                }
                NavigationLink(destination: AgenticUIActionStreamView()) {
                    Label("Live Action Stream", systemImage: "list.bullet.indent")
                }
                NavigationLink(destination: AgenticUIDebugPanel()) {
                    Label("Agent Debug Panel", systemImage: "ladybug")
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Agentic System")
    }
}

struct AgenticTraceRow: View {
    let trace: AgenticExecutionTrace

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(trace.toolName)
                    .font(.headline)
                Spacer()
                AgenticStatusPill(status: trace.status)
            }

            Text(trace.status.rawValue.capitalized)
                .font(.caption)
                .foregroundStyle(.secondary)

            if let output = trace.output {
                Text(output.summary)
                    .font(.subheadline)
                    .lineLimit(2)
                    .padding(.top, 2)
            }
        }
        .padding(.vertical, 4)
    }
}

struct AgenticStatusPill: View {
    let status: AgenticExecutionStatus

    var color: Color {
        switch status {
        case .preparing: return .orange
        case .running: return .blue
        case .completed: return .green
        case .failed: return .red
        }
    }

    var body: some View {
        Text(status.rawValue.uppercased())
            .font(.system(size: 10, weight: .bold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.2))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }
}
