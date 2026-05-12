import SwiftUI

struct AgenticUIActionStreamView: View {
    @StateObject private var orchestrator = AgenticCoreOrchestrator.shared
    @StateObject private var sessionManager = AgenticCoreSessionManager.shared
    @StateObject private var traceStore = AgenticExecutionTraceStore.shared

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 8) {
                    executionStateHeader
                    tokenStreamSection
                    actionsSection
                    toolOutputsSection
                }
                .padding()
            }
            .navigationTitle("Action Stream")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Execution State

    private var executionStateHeader: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    stateIndicator(orchestrator.executionState)
                    Spacer()
                    Text("Iteration \(orchestrator.iterationCount)")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }

                if sessionManager.isStreaming {
                    ProgressView(value: 0.5)
                        .progressViewStyle(.linear)
                }
            }
        } label: {
            Label("Execution", systemImage: "play.circle")
        }
    }

    private func stateIndicator(_ state: AgenticExecutionState) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(colorForState(state))
                .frame(width: 8, height: 8)

            Text(state.rawValue.capitalized)
                .font(.subheadline.bold())
        }
    }

    private func colorForState(_ state: AgenticExecutionState) -> Color {
        switch state {
        case .idle: return .gray
        case .preparing: return .yellow
        case .streaming: return .blue
        case .executingTool: return .orange
        case .completed: return .green
        case .failed: return .red
        case .interrupted: return .purple
        }
    }

    // MARK: - Token Stream

    private var tokenStreamSection: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("\(sessionManager.streamedTokens.count) tokens")
                        .font(.caption.monospacedDigit())
                    Spacer()
                    if sessionManager.isStreaming {
                        ProgressView()
                            .controlSize(.small)
                    }
                }

                if !sessionManager.currentResponse.isEmpty {
                    Text(sessionManager.currentResponse)
                        .font(.system(.caption, design: .monospaced))
                        .lineLimit(10)
                        .padding(8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.fill.quaternary, in: RoundedRectangle(cornerRadius: 6))
                }
            }
        } label: {
            Label("Token Stream", systemImage: "text.word.spacing")
        }
    }

    // MARK: - Actions

    private var actionsSection: some View {
        GroupBox {
            if orchestrator.currentActions.isEmpty {
                Text("No actions emitted")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(orchestrator.currentActions.indices, id: \.self) { index in
                    let action = orchestrator.currentActions[index]
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Image(systemName: "gearshape.fill")
                                .foregroundStyle(.orange)
                            Text(action.toolName)
                                .font(.subheadline.bold())
                        }

                        ForEach(Array(action.parameters.keys.sorted()), id: \.self) { key in
                            HStack {
                                Text(key)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                Text(action.parameters[key] ?? "")
                                    .font(.caption2)
                                    .lineLimit(1)
                            }
                        }

                        Text("Expected: \(action.expectedOutcome)")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.fill.quaternary, in: RoundedRectangle(cornerRadius: 8))
                }
            }
        } label: {
            Label("Actions (\(orchestrator.currentActions.count))", systemImage: "bolt.fill")
        }
    }

    // MARK: - Tool Outputs

    private var toolOutputsSection: some View {
        GroupBox {
            if orchestrator.toolOutputs.isEmpty {
                Text("No tool outputs yet")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(Array(orchestrator.toolOutputs.keys.sorted()), id: \.self) { toolName in
                    if let output = orchestrator.toolOutputs[toolName] {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                                Text(toolName)
                                    .font(.subheadline.bold())
                            }

                            Text(output.summary)
                                .font(.caption)

                            if let code = output.generatedCode {
                                DisclosureGroup("Code Output") {
                                    Text(code.prefix(500))
                                        .font(.system(.caption2, design: .monospaced))
                                        .lineLimit(15)
                                }
                                .font(.caption2)
                            }
                        }
                        .padding(8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.fill.quaternary, in: RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
        } label: {
            Label("Tool Outputs (\(orchestrator.toolOutputs.count))", systemImage: "tray.full")
        }
    }
}
