import SwiftUI

struct AgenticUIDebugPanel: View {
    @StateObject private var orchestrator = AgenticCoreOrchestrator.shared
    @StateObject private var sessionManager = AgenticCoreSessionManager.shared
    @StateObject private var toolRegistry = WorkspaceAITools.shared
    @StateObject private var toolExecutor = AgenticToolExecutor.shared
    @State private var isCheckingAvailability = false
    @State private var availabilityResult: FoundationModelsStatus?

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                availabilitySection
                systemStateSection
                diagnosticsSection
                tokenStreamSection
            }
            .padding()
        }
    }

    // MARK: - Foundation Models Availability

    private var availabilitySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "cpu")
                    .foregroundStyle(.accentColor)
                Text("Foundation Models")
                    .font(.headline)
                Spacer()
                Button {
                    checkAvailability()
                } label: {
                    if isCheckingAvailability {
                        ProgressView()
                            .scaleEffect(0.7)
                    } else {
                        Text("Check")
                            .font(.caption)
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .disabled(isCheckingAvailability)
            }

            let status = availabilityResult ?? orchestrator.availabilityStatus

            if let status = status {
                VStack(spacing: 6) {
                    statusRow(label: "Framework Available", value: status.isFrameworkAvailable)
                    statusRow(label: "Runtime Available", value: status.isRuntimeAvailable)
                    statusRow(label: "Session Ready", value: status.isSessionReady)
                    statusRow(label: "Fully Available", value: status.isFullyAvailable)

                    Text(status.diagnosticMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 8))

                    Text("Checked: \(status.checkedAt, style: .relative) ago")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            } else {
                Text("Availability not checked yet. Tap 'Check' to run diagnostics.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func statusRow(label: String, value: Bool) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
            Spacer()
            Image(systemName: value ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundStyle(value ? .green : .red)
            Text(value ? "Yes" : "No")
                .font(.subheadline)
                .foregroundStyle(value ? .green : .red)
        }
    }

    // MARK: - System State

    private var systemStateSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "gauge.with.dots.needle.33percent")
                    .foregroundStyle(.accentColor)
                Text("System State")
                    .font(.headline)
            }

            VStack(spacing: 8) {
                infoRow(label: "Orchestrator State", value: orchestrator.state.rawValue.capitalized)
                infoRow(label: "Is Streaming", value: sessionManager.isStreaming ? "Yes" : "No")
                infoRow(label: "Token Count", value: "\(sessionManager.tokens.count)")
                infoRow(label: "Execution Steps", value: "\(sessionManager.executionSteps.count)")
                infoRow(label: "Registered Tools", value: "\(toolRegistry.registeredTools.count)")
                infoRow(label: "Tools Executed", value: "\(toolExecutor.executionLog.count)")

                if let graph = orchestrator.workspaceGraph {
                    Divider()
                    infoRow(label: "Workspace Modules", value: "\(graph.modules.count)")
                    infoRow(label: "Total Files", value: "\(graph.totalFileCount)")
                    infoRow(label: "Feature Domains", value: "\(graph.featureDomains.count)")
                    infoRow(label: "Relationships", value: "\(graph.relationships.count)")
                    infoRow(label: "Last Scan", value: graph.scannedAt.formatted(.dateTime.hour().minute().second()))
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.medium))
        }
    }

    // MARK: - Diagnostics

    private var diagnosticsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "exclamationmark.triangle")
                    .foregroundStyle(.accentColor)
                Text("Diagnostics")
                    .font(.headline)
                Spacer()
                Text("\(sessionManager.diagnostics.count)")
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.accentColor.opacity(0.15))
                    .clipShape(Capsule())
            }

            if sessionManager.diagnostics.isEmpty {
                Text("No diagnostics recorded.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(sessionManager.diagnostics) { diagnostic in
                    diagnosticRow(diagnostic)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func diagnosticRow(_ diagnostic: AgenticDiagnostic) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: diagnosticIcon(diagnostic.level))
                .font(.caption)
                .foregroundStyle(diagnosticColor(diagnostic.level))
                .frame(width: 16)

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(diagnostic.component)
                        .font(.caption.weight(.semibold))
                    Spacer()
                    Text(diagnostic.timestamp, style: .time)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                Text(diagnostic.message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(8)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Token Stream

    private var tokenStreamSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "text.line.first.and.arrowtriangle.forward")
                    .foregroundStyle(.accentColor)
                Text("Token Stream")
                    .font(.headline)
                Spacer()
                Text("\(sessionManager.tokens.count) tokens")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if sessionManager.tokens.isEmpty {
                Text("No tokens streamed yet.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(sessionManager.tokens.suffix(50)) { token in
                            Text(token.content)
                                .font(.system(.caption2, design: .monospaced))
                                .padding(.horizontal, 4)
                                .padding(.vertical, 2)
                                .background(tokenColor(token.tokenType).opacity(0.15))
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                        }
                    }
                    .padding(.vertical, 4)
                }

                HStack(spacing: 12) {
                    tokenLegendItem(type: "Text", color: .primary)
                    tokenLegendItem(type: "Reasoning", color: .blue)
                    tokenLegendItem(type: "Tool Call", color: .purple)
                    tokenLegendItem(type: "Result", color: .green)
                    tokenLegendItem(type: "Error", color: .red)
                }
                .font(.caption2)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func tokenLegendItem(type: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            Text(type)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Helpers

    private func checkAvailability() {
        isCheckingAvailability = true
        Task {
            let result = await AgenticFoundationModelsAvailabilityChecker.shared.checkFullAvailability()
            availabilityResult = result
            isCheckingAvailability = false
        }
    }

    private func diagnosticIcon(_ level: AgenticDiagnostic.DiagnosticLevel) -> String {
        switch level {
        case .info: return "info.circle"
        case .warning: return "exclamationmark.triangle"
        case .error: return "xmark.octagon"
        case .success: return "checkmark.circle"
        }
    }

    private func diagnosticColor(_ level: AgenticDiagnostic.DiagnosticLevel) -> Color {
        switch level {
        case .info: return .blue
        case .warning: return .orange
        case .error: return .red
        case .success: return .green
        }
    }

    private func tokenColor(_ type: AgenticStreamToken.TokenType) -> Color {
        switch type {
        case .text: return .primary
        case .reasoning: return .blue
        case .toolCall: return .purple
        case .toolResult: return .green
        case .error: return .red
        }
    }
}
