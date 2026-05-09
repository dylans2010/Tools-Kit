/*
 REDESIGN SUMMARY:
 - Standardized on a modern, vertical-scroll execution interface.
 - Modernized the header with semantic colors, symbols, and a monospaced timer pill.
 - Replaced manual timeline with a structured ExecutionTimelineSection using native SF Symbols and progress indicators.
 - Standardized execution history using a native List/Section pattern with semantic log level badges.
 - Replaced manual stats card with a centered group of DetailMetricPills.
 - strictly preserved all ConnectorRuntime integration, Timer logic, and execution mode switching.
 - Improved visual hierarchy for flow preview using native Capsules and arrows.
 - Extracted subviews for ExecutionTimelineSection, ExecutionHistorySection, and ExecutionStatsSection.
 - Modernized the parameters sheet with native LabeledContent and semantic sections.
 */

import SwiftUI

struct ConnectorExecutionView: View {
    @State var connector: ConnectorDefinition
    @StateObject private var runtime = ConnectorRuntime.shared
    @StateObject private var manager = ConnectorManager.shared
    @State private var executionStartTime: Date?
    @State private var elapsedTime: TimeInterval = 0
    @State private var timer: Timer?
    @State private var showingParameters = false
    @State private var selectedStepIndex: Int?
    @State private var executionMode: ExecutionMode = .full

    enum ExecutionMode: String, CaseIterable {
        case full = "Full Pipeline"
        case stepByStep = "Step-by-Step"
        case dryRun = "Dry Run"
    }

    var isRunning: Bool { runtime.activeRunningConnectors.contains(connector.id) }
    var recentLogs: [ConnectorLog] { manager.logs.filter { $0.connectorID == connector.id }.prefix(10).map { $0 } }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                ExecutionHeaderView(connector: connector, isRunning: isRunning, elapsedTime: elapsedTime, executionMode: $executionMode)

                if isRunning {
                    ExecutionTimelineSection(connector: connector, selectedStepIndex: selectedStepIndex)
                } else if !recentLogs.isEmpty {
                    ExecutionHistorySection(logs: recentLogs)
                } else {
                    ContentUnavailableView("No Activity", systemImage: "bolt.slash", description: Text("Run the pipeline to see execution details here."))
                }

                if connector.metadata.executionCount > 0 {
                    ExecutionStatsSection(metadata: connector.metadata)
                }

                if !connector.flow.steps.isEmpty {
                    ExecutionFlowPreview(steps: connector.flow.steps)
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Live Execution")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: isRunning) { _, running in
            if running { executionStartTime = Date(); startTimer() }
            else { stopTimer() }
        }
        .safeAreaInset(edge: .bottom) {
            ExecutionActionBar(isRunning: isRunning, stepsEmpty: connector.flow.steps.isEmpty, onCancel: stopTimer, onParams: { showingParameters = true }) {
                Task { await runtime.run(connector: connector) }
            }
        }
        .sheet(isPresented: $showingParameters) {
            ExecutionParametersSheet(connector: connector, executionMode: $executionMode)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(20)
        }
    }

    private func startTimer() {
        elapsedTime = 0
        timer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { _ in
            if let start = executionStartTime { elapsedTime = Date().timeIntervalSince(start) }
        }
    }

    private func stopTimer() { timer?.invalidate(); timer = nil }
}

// MARK: - Private Subviews

private struct ExecutionHeaderView: View {
    let connector: ConnectorDefinition
    let isRunning: Bool
    let elapsedTime: TimeInterval
    @Binding var executionMode: ConnectorExecutionView.ExecutionMode

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: isRunning ? "arrow.triangle.2.circlepath" : "play.circle.fill")
                .font(.system(size: 48)).foregroundStyle(isRunning ? .accent : .secondary)
                .symbolEffect(.bounce, options: .repeating, value: isRunning)

            VStack(spacing: 4) {
                Text(isRunning ? "Executing Pipeline" : "Pipeline Ready").font(.headline)
                Text(connector.name).font(.subheadline).foregroundStyle(.secondary)
            }

            if isRunning {
                Text(formatElapsedTime(elapsedTime))
                    .font(.system(.caption, design: .monospaced))
                    .padding(.horizontal, 10).padding(.vertical, 4)
                    .background(Color.accentColor.opacity(0.1), in: Capsule())
                    .foregroundStyle(.accent)
            } else {
                Picker("Mode", selection: $executionMode) {
                    ForEach(ConnectorExecutionView.ExecutionMode.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented).padding(.horizontal, 16)
            }
        }
        .frame(maxWidth: .infinity).padding(.vertical, 8)
    }

    private func formatElapsedTime(_ interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        let ms = Int((interval.truncatingRemainder(dividingBy: 1)) * 100)
        return String(format: "%02d:%02d.%02d", minutes, seconds, ms)
    }
}

private struct ExecutionTimelineSection: View {
    let connector: ConnectorDefinition
    let selectedStepIndex: Int?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Step-by-Step Progress", systemImage: "list.number").font(.caption.bold()).foregroundStyle(.secondary)

            VStack(spacing: 8) {
                ForEach(Array(connector.flow.steps.enumerated()), id: \.element.id) { index, step in
                    HStack(spacing: 12) {
                        StepIndicator(index: index, selectedIndex: selectedStepIndex)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(step.type.rawValue.capitalized).font(.subheadline.bold())
                            if let name = step.config["name"] { Text(name).font(.caption2).foregroundStyle(.secondary) }
                        }
                        Spacer()
                        StepStatusView(index: index, selectedIndex: selectedStepIndex)
                    }
                    .padding(12).background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }
}

private struct StepIndicator: View {
    let index: Int
    let selectedIndex: Int?
    var body: some View {
        ZStack {
            Circle().fill(color).frame(width: 24, height: 24)
            Text("\(index + 1)").font(.system(size: 10, weight: .bold)).foregroundStyle(.white)
        }
    }
    private var color: Color {
        guard let selected = selectedIndex else { return .accentColor }
        if index < selected { return .green }
        if index == selected { return .accentColor }
        return .secondary.opacity(0.3)
    }
}

private struct StepStatusView: View {
    let index: Int
    let selectedIndex: Int?
    var body: some View {
        if let selected = selectedIndex {
            if index < selected { Image(systemName: "checkmark.circle.fill").foregroundStyle(.green) }
            else if index == selected { ProgressView().controlSize(.small) }
            else { Image(systemName: "circle").foregroundStyle(.secondary.opacity(0.3)) }
        } else { ProgressView().controlSize(.small) }
    }
}

private struct ExecutionHistorySection: View {
    let logs: [ConnectorLog]
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Recent History", systemImage: "clock.arrow.circlepath").font(.caption.bold()).foregroundStyle(.secondary)
            VStack(spacing: 8) {
                ForEach(logs) { log in
                    HStack(spacing: 12) {
                        Circle().fill(log.type.color).frame(width: 6, height: 6)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(log.message).font(.subheadline).lineLimit(1)
                            Text(log.timestamp.formatted(.relative(presentation: .named))).font(.caption2).foregroundStyle(.tertiary)
                        }
                        Spacer()
                        Text(log.type.rawValue.uppercased()).font(.system(size: 8, weight: .black))
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(log.type.color.opacity(0.1), in: Capsule()).foregroundStyle(log.type.color)
                    }
                    .padding(12).background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }
}

private struct ExecutionStatsSection: View {
    let metadata: ConnectorDefinition.Metadata
    var body: some View {
        HStack(spacing: 0) {
            DetailMetricPill(label: "Runs", value: "\(metadata.executionCount)", color: .blue)
            DetailMetricPill(label: "Latency", value: String(format: "%.0fms", metadata.averageLatency), color: .purple)
            DetailMetricPill(label: "Errors", value: String(format: "%.1f%%", metadata.errorRate * 100), color: metadata.errorRate > 0.1 ? .red : .green)
        }
        .padding(16).background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
    }
}

private struct ExecutionFlowPreview: View {
    let steps: [FlowStep]
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Pipeline Sequence", systemImage: "arrow.triangle.branch").font(.caption.bold()).foregroundStyle(.secondary)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Array(steps.enumerated()), id: \.element.id) { index, step in
                        HStack(spacing: 6) {
                            stepIcon(step.type).font(.caption2)
                            Text(step.type.rawValue.capitalized).font(.caption2.bold())
                        }
                        .padding(.horizontal, 10).padding(.vertical, 6)
                        .background(stepTypeColor(step.type).opacity(0.1), in: Capsule())
                        .foregroundStyle(stepTypeColor(step.type))

                        if index < steps.count - 1 { Image(systemName: "chevron.right").font(.system(size: 8, weight: .bold)).foregroundStyle(.tertiary) }
                    }
                }
            }
        }
    }
    private func stepIcon(_ type: FlowStep.StepType) -> Image {
        switch type {
        case .trigger: return Image(systemName: "bolt.fill")
        case .condition: return Image(systemName: "arrow.branch")
        case .action: return Image(systemName: "play.fill")
        case .delay: return Image(systemName: "clock.fill")
        }
    }
    private func stepTypeColor(_ type: FlowStep.StepType) -> Color {
        switch type {
        case .trigger: return .orange
        case .condition: return .purple
        case .action: return .blue
        case .delay: return .secondary
        }
    }
}

private struct ExecutionActionBar: View {
    let isRunning: Bool
    let stepsEmpty: Bool
    let onCancel: () -> Void
    let onParams: () -> Void
    let onStart: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            if isRunning {
                Button(action: onCancel) {
                    Text("Cancel Execution").frame(maxWidth: .infinity).bold()
                }
                .buttonStyle(.borderedProminent).tint(.red).controlSize(.large)
            } else {
                Button(action: onParams) {
                    Image(systemName: "gearshape.fill").font(.title3)
                }
                .buttonStyle(.bordered).controlSize(.large)

                Button(action: onStart) {
                    Text("Start Pipeline").frame(maxWidth: .infinity).bold()
                }
                .buttonStyle(.borderedProminent).controlSize(.large)
                .disabled(stepsEmpty)
            }
        }
        .padding().background(.ultraThinMaterial)
    }
}

private struct ExecutionParametersSheet: View {
    let connector: ConnectorDefinition
    @Binding var executionMode: ConnectorExecutionView.ExecutionMode
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Runtime Policy") {
                    Picker("Mode", selection: $executionMode) {
                        ForEach(ConnectorExecutionView.ExecutionMode.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                    }.pickerStyle(.menu)
                    Text(modeDescription).font(.caption).foregroundStyle(.secondary)
                }
                Section("Environment") {
                    LabeledContent("Connector", value: connector.name)
                    LabeledContent("Endpoints", value: "\(connector.endpoints.count)")
                    LabeledContent("Auth Type", value: connector.authConfig.type.rawValue.capitalized)
                }
            }
            .navigationTitle("Parameters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } } }
        }
    }
    private var modeDescription: String {
        switch executionMode {
        case .full: return "Executes the entire pipeline sequence automatically."
        case .stepByStep: return "Pauses after each step for manual verification."
        case .dryRun: return "Simulates responses without making network calls."
        }
    }
}

private struct DetailMetricPill: View {
    let label: String
    let value: String
    let color: Color
    var body: some View {
        VStack(spacing: 4) {
            Text(value).font(.headline).foregroundStyle(color)
            Text(label).font(.caption2.bold()).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

extension ConnectorLog.LogType {
    var color: Color {
        switch self {
        case .info: return .blue
        case .warning: return .orange
        case .error: return .red
        case .performance: return .purple
        }
    }
}
