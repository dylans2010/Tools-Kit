import SwiftUI

struct AgenticUIActionStreamView: View {
    @StateObject private var traceStore = AgenticExecutionTraceStore.shared

    var body: some View {
        List {
            if traceStore.traces.isEmpty {
                ContentUnavailableView("Stream Empty", systemImage: "stream.fill", description: Text("Executed tool actions will appear here in sequence."))
            } else {
                ForEach(traceStore.traces.reversed()) { trace in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(trace.timestamp, style: .time)
                                .font(.caption.monospaced())
                                .foregroundStyle(.secondary)
                            Text(trace.toolName)
                                .font(.subheadline.bold())
                            Spacer()
                            AgenticStatusPill(status: trace.status)
                        }

                        Text("Params: \(trace.parameters.description)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)

                        if let summary = trace.output?.summary {
                            Text(summary)
                                .font(.caption)
                                .foregroundStyle(.primary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("Action Stream")
    }
}
