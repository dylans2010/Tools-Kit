import SwiftUI

struct AgenticUIActionStreamView: View {
    @StateObject private var orchestrator = AgenticCoreOrchestrator.shared
    @StateObject private var sessionManager = AgenticCoreSessionManager.shared
    @StateObject private var toolExecutor = AgenticToolExecutor.shared
    @StateObject private var toolRegistry = WorkspaceAITools.shared

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                orchestrationEventsSection
                executionStepsSection
                toolExecutionLogSection
                registeredToolsSection
            }
            .padding()
        }
    }

    // MARK: - Orchestration Events

    private var orchestrationEventsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader(title: "Orchestration Events", icon: "arrow.triangle.2.circlepath", count: orchestrator.orchestrationLog.count)

            if orchestrator.orchestrationLog.isEmpty {
                emptyCard(message: "No orchestration events yet. Send a message to start the agentic loop.")
            } else {
                ForEach(orchestrator.orchestrationLog) { event in
                    orchestrationEventRow(event)
                }
            }
        }
    }

    private func orchestrationEventRow(_ event: AgenticCoreOrchestrator.OrchestrationEvent) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Circle()
                .fill(eventStatusColor(event.status))
                .frame(width: 8, height: 8)
                .padding(.top, 6)

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(event.phase)
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    Text(event.status.rawValue)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(eventStatusColor(event.status).opacity(0.15))
                        .clipShape(Capsule())
                }

                Text(event.message)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(event.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(10)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Execution Steps

    private var executionStepsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader(title: "Execution Steps", icon: "list.bullet.rectangle", count: sessionManager.executionSteps.count)

            if sessionManager.executionSteps.isEmpty {
                emptyCard(message: "No execution steps recorded.")
            } else {
                ForEach(sessionManager.executionSteps) { step in
                    executionStepRow(step)
                }
            }
        }
    }

    private func executionStepRow(_ step: AgenticExecutionStep) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: stepIcon(step.status))
                .font(.caption)
                .foregroundStyle(stepColor(step.status))
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(step.action)
                    .font(.subheadline.weight(.medium))

                if let toolName = step.toolName {
                    Text("Tool: \(toolName)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if let input = step.input {
                    Text("Input: \(input)")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .lineLimit(2)
                }

                if let output = step.output {
                    Text("Output: \(output)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                }

                if let completedAt = step.completedAt {
                    let duration = completedAt.timeIntervalSince(step.startedAt)
                    Text(String(format: "%.2fs", duration))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(10)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Tool Execution Log

    private var toolExecutionLogSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader(title: "Tool Execution Log", icon: "wrench.and.screwdriver", count: toolExecutor.executionLog.count)

            if toolExecutor.executionLog.isEmpty {
                emptyCard(message: "No tools have been executed yet.")
            } else {
                ForEach(toolExecutor.executionLog) { entry in
                    toolExecutionRow(entry)
                }
            }
        }
    }

    private func toolExecutionRow(_ entry: AgenticToolExecutor.ToolExecutionEntry) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "hammer")
                    .font(.caption)
                    .foregroundStyle(.purple)
                Text(entry.toolName)
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text(String(format: "%.2fs", entry.duration))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Text(entry.output.summary)
                .font(.caption)
                .foregroundStyle(.secondary)

            if !entry.output.metadata.isEmpty {
                HStack(spacing: 6) {
                    ForEach(Array(entry.output.metadata.prefix(3)), id: \.key) { key, value in
                        Text("\(key): \(value)")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color(.systemGray5))
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .padding(10)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Registered Tools

    private var registeredToolsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader(title: "Dynamic Tools", icon: "wand.and.stars", count: toolRegistry.registeredTools.count)

            if toolRegistry.isGenerating {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Generating tools from workspace...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
            } else if toolRegistry.registeredTools.isEmpty {
                emptyCard(message: "No tools generated yet. Analyze workspace to generate tools.")
            } else {
                ForEach(toolRegistry.registeredTools) { tool in
                    toolDefinitionRow(tool)
                }
            }
        }
    }

    private func toolDefinitionRow(_ tool: AgenticToolDefinition) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(tool.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.accentColor)
                Spacer()
                Text(tool.sourceModule)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Text(tool.description)
                .font(.caption)
                .foregroundStyle(.secondary)

            if !tool.parameters.isEmpty {
                HStack(spacing: 4) {
                    ForEach(tool.parameters, id: \.name) { param in
                        Text("\(param.name):\(param.type)")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(param.required ? Color.orange.opacity(0.15) : Color(.systemGray5))
                            .clipShape(Capsule())
                    }
                }
            }

            Text("Derived from: \(tool.derivedFrom)")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .lineLimit(1)
        }
        .padding(10)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Helpers

    private func sectionHeader(title: String, icon: String, count: Int) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(.accentColor)
            Text(title)
                .font(.headline)
            Spacer()
            if count > 0 {
                Text("\(count)")
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.accentColor.opacity(0.15))
                    .clipShape(Capsule())
            }
        }
    }

    private func emptyCard(message: String) -> some View {
        Text(message)
            .font(.caption)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding()
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func eventStatusColor(_ status: AgenticCoreOrchestrator.OrchestrationEvent.EventStatus) -> Color {
        switch status {
        case .started: return .blue
        case .completed: return .green
        case .failed: return .red
        case .skipped: return .gray
        }
    }

    private func stepIcon(_ status: AgenticExecutionStep.StepStatus) -> String {
        switch status {
        case .pending: return "circle"
        case .running: return "circle.dotted"
        case .completed: return "checkmark.circle.fill"
        case .failed: return "xmark.circle.fill"
        }
    }

    private func stepColor(_ status: AgenticExecutionStep.StepStatus) -> Color {
        switch status {
        case .pending: return .gray
        case .running: return .blue
        case .completed: return .green
        case .failed: return .red
        }
    }
}
