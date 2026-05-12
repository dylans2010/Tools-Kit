import SwiftUI

struct AgenticUIChatView: View {
    @StateObject private var orchestrator = AgenticCoreOrchestrator.shared
    @StateObject private var traceStore = AgenticExecutionTraceStore.shared
    @State private var query = ""

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(traceStore.traces) { trace in
                        AgenticExecutionCard(trace: trace)
                    }

                    if orchestrator.isProcessing {
                        HStack {
                            ProgressView()
                                .padding(.trailing, 8)
                            Text("Agent is reasoning...")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                        }
                        .padding()
                    }
                }
                .padding()
            }

            VStack {
                Divider()
                HStack {
                    TextField("Command the agent...", text: $query)
                        .textFieldStyle(.roundedBorder)
                        .disabled(orchestrator.isProcessing)

                    Button(action: sendMessage) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 32))
                    }
                    .disabled(query.isEmpty || orchestrator.isProcessing)
                }
                .padding()
            }
            .background(.ultraThinMaterial)
        }
        .navigationTitle("Agent Chat")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func sendMessage() {
        let text = query
        query = ""
        Task {
            await orchestrator.processRequest(text)
        }
    }
}

struct AgenticExecutionCard: View {
    let trace: AgenticExecutionTrace

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "bolt.fill")
                    .foregroundStyle(.orange)
                Text(trace.toolName)
                    .font(.headline)
                Spacer()
                AgenticStatusPill(status: trace.status)
            }

            Divider()

            VStack(alignment: .leading, spacing: 4) {
                Text("Reason for execution:")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                Text("Requested via user intent")
                    .font(.subheadline)
            }

            if let output = trace.output {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Output Summary:")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                    Text(output.summary)
                        .font(.subheadline)
                }

                if let code = output.generatedCode {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Generated Code:")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                        ScrollView(.horizontal) {
                            Text(code)
                                .font(.system(.caption, design: .monospaced))
                                .padding(8)
                                .background(Color.black.opacity(0.05))
                                .cornerRadius(8)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(12)
    }
}
