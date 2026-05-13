
import SwiftUI

struct ConnectorPipelineView: View {
    @State private var steps: [PipelineStep] = []

    struct PipelineStep: Identifiable {
        let id = UUID()
        var name: String
        var script: String
    }

    var body: some View {
        List {
            Section("Transformation Pipeline") {
                if steps.isEmpty {
                    Text("No processing steps defined.").font(.caption).foregroundStyle(.secondary)
                } else {
                    ForEach(steps) { step in
                        VStack(alignment: .leading) {
                            Text(step.name).bold()
                            Text(step.script).font(.system(.caption2, design: .monospaced)).lineLimit(1).foregroundStyle(.secondary)
                        }
                    }
                    .onDelete { steps.remove(atOffsets: $0) }
                }
            }

            Button("Add Processing Step", systemImage: "plus") {
                steps.append(PipelineStep(name: "New Step", script: "return data;"))
            }
        }
        .navigationTitle("Data Pipeline")
    }
}
