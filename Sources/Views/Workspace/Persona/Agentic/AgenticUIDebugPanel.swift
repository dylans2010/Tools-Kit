import SwiftUI

struct AgenticUIDebugPanel: View {
    @StateObject private var traceStore = AgenticExecutionTraceStore.shared
    @StateObject private var registry = WorkspaceAITools.shared
    @StateObject private var orchestrator = AgenticCoreOrchestrator.shared
    @State private var selectedTab = 0
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("View", selection: $selectedTab) {
                    Text("Trace").tag(0)
                    Text("Registry").tag(1)
                    Text("Stream").tag(2)
                    Text("Stats").tag(3)
                }
                .pickerStyle(.segmented)
                .padding()

                switch selectedTab {
                case 0: traceView
                case 1: registryView
                case 2: AgenticUIActionStreamView()
                case 3: statsView
                default: EmptyView()
                }
            }
            .navigationTitle("Debug Panel")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button("Clear Traces") { traceStore.clear() }
                        Button("Reset Orchestrator") { orchestrator.reset() }
                        Button("Export Traces") { exportTraces() }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
    }

    // MARK: - Trace View

    private var traceView: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 6) {
                if traceStore.entries.isEmpty {
                    ContentUnavailableView("No Traces", systemImage: "doc.text.magnifyingglass", description: Text("Execute a prompt to see trace entries"))
                } else {
                    ForEach(traceStore.entries) { entry in
                        traceEntryRow(entry)
                    }
                }
            }
            .padding()
        }
    }

    private func traceEntryRow(_ entry: AgenticTraceEntry) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: iconForPhase(entry.phase))
                    .font(.caption)
                    .foregroundStyle(colorForPhase(entry.phase))

                Text(entry.phase.uppercased())
                    .font(.caption2.bold())
                    .foregroundStyle(colorForPhase(entry.phase))

                if let toolName = entry.toolName {
                    Text(toolName)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 1)
                        .background(.orange.opacity(0.2), in: Capsule())
                }

                Spacer()

                if let duration = entry.durationMs {
                    Text("\(String(format: "%.1f", duration))ms")
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.secondary)
                }

                Text(entry.timestamp, style: .time)
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.tertiary)
            }

            Text(entry.detail)
                .font(.caption)
                .lineLimit(3)

            if let input = entry.inputSnapshot, !input.isEmpty {
                DisclosureGroup("Input") {
                    ForEach(Array(input.keys.sorted()), id: \.self) { key in
                        HStack {
                            Text(key).font(.caption2).foregroundStyle(.secondary)
                            Text(input[key] ?? "").font(.caption2).lineLimit(1)
                        }
                    }
                }
                .font(.caption2)
            }

            if let output = entry.outputSnapshot, !output.isEmpty {
                DisclosureGroup("Output") {
                    ForEach(Array(output.keys.sorted()), id: \.self) { key in
                        HStack {
                            Text(key).font(.caption2).foregroundStyle(.secondary)
                            Text(output[key] ?? "").font(.caption2).lineLimit(1)
                        }
                    }
                }
                .font(.caption2)
            }
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.fill.quaternary, in: RoundedRectangle(cornerRadius: 8))
    }

    private func iconForPhase(_ phase: String) -> String {
        switch phase {
        case "session": return "bolt.circle"
        case "streaming": return "waveform"
        case "tool_start": return "play.circle"
        case "tool_end": return "checkmark.circle"
        case "error": return "exclamationmark.triangle"
        case "iteration": return "arrow.clockwise"
        case "capability_check": return "cpu"
        case "registry_load": return "wrench.and.screwdriver"
        case "complete": return "flag.checkered"
        default: return "circle"
        }
    }

    private func colorForPhase(_ phase: String) -> Color {
        switch phase {
        case "error": return .red
        case "tool_start": return .orange
        case "tool_end": return .green
        case "streaming": return .blue
        case "complete": return .green
        default: return .secondary
        }
    }

    // MARK: - Registry View

    private var registryView: some View {
        List {
            ForEach(registry.categories, id: \.self) { category in
                Section(category.replacingOccurrences(of: "_", with: " ").capitalized) {
                    ForEach(registry.tools(inCategory: category)) { tool in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(tool.name)
                                    .font(.subheadline.bold())
                                Spacer()
                                if tool.producesCode {
                                    Image(systemName: "chevron.left.forwardslash.chevron.right")
                                        .font(.caption2)
                                        .foregroundStyle(.purple)
                                }
                                if tool.deterministic {
                                    Image(systemName: "function")
                                        .font(.caption2)
                                        .foregroundStyle(.green)
                                }
                            }
                            Text(tool.description)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            HStack {
                                ForEach(Array(tool.inputSchema.keys.sorted()), id: \.self) { key in
                                    Text("\(key): \(tool.inputSchema[key] ?? "")")
                                        .font(.caption2)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 1)
                                        .background(.fill.tertiary, in: Capsule())
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Stats View

    private var statsView: some View {
        List {
            Section("Execution") {
                LabeledContent("State", value: orchestrator.executionState.rawValue.capitalized)
                LabeledContent("Iterations", value: "\(orchestrator.iterationCount)")
                LabeledContent("Tool Outputs", value: "\(orchestrator.toolOutputs.count)")
            }

            Section("Registry") {
                LabeledContent("Total Tools", value: "\(registry.tools.count)")
                LabeledContent("Categories", value: "\(registry.categories.count)")
                LabeledContent("Code-producing", value: "\(registry.tools.filter(\.producesCode).count)")
            }

            Section("Traces") {
                LabeledContent("Total Entries", value: "\(traceStore.entries.count)")
                LabeledContent("Total Duration", value: "\(String(format: "%.1f", traceStore.totalDurationMs))ms")
                LabeledContent("Errors", value: "\(traceStore.entriesForPhase("error").count)")
                LabeledContent("Tool Executions", value: "\(traceStore.entriesForPhase("tool_end").count)")
            }
        }
    }

    // MARK: - Export

    private func exportTraces() {
        guard let data = try? traceStore.exportJSON(),
              let json = String(data: data, encoding: .utf8) else { return }
        UIPasteboard.general.string = json
    }
}
