import SwiftUI

struct AgenticUIDebugPanel: View {
    @StateObject private var orchestrator = AgenticCoreOrchestrator.shared
    @StateObject private var traceStore = AgenticExecutionTraceStore.shared

    var body: some View {
        Form {
            Section("System Status") {
                HStack {
                    Text("Orchestrator State")
                    Spacer()
                    Text(orchestrator.isProcessing ? "Processing" : "Idle")
                        .foregroundStyle(orchestrator.isProcessing ? .blue : .secondary)
                }

                HStack {
                    Text("Total Tool Executions")
                    Spacer()
                    Text("\(traceStore.traces.count)")
                }
            }

            Section("Tool Registry") {
                ForEach(WorkspaceAITools.registry, id: \.name) { tool in
                    VStack(alignment: .leading) {
                        Text(tool.name).font(.headline)
                        Text(tool.description).font(.caption).foregroundStyle(.secondary)
                        Text("Category: \(tool.category)").font(.caption2)
                    }
                }
            }

            Section {
                Button("Clear Trace History", role: .destructive) {
                    traceStore.clear()
                }
            }
        }
        .navigationTitle("Agent Debug")
    }
}
