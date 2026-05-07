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

    var isRunning: Bool {
        runtime.activeRunningConnectors.contains(connector.id)
    }

    var recentLogs: [ConnectorLog] {
        manager.logs.filter { $0.connectorID == connector.id }.prefix(10).map { $0 }
    }

    var body: some View {
        VStack(spacing: 0) {
            executionHeader

            ScrollView {
                VStack(spacing: 16) {
                    if isRunning {
                        executionTimeline
                    } else if !recentLogs.isEmpty {
                        executionHistory
                    } else {
                        idleState
                    }

                    // MARK: - Execution Stats
                    if connector.metadata.executionCount > 0 {
                        statsCard
                    }

                    // MARK: - Flow Preview
                    if !connector.flow.steps.isEmpty {
                        flowPreview
                    }
                }
                .padding(.vertical)
            }

            actionBar
        }
        .navigationTitle("Live Execution")
        .background(Color(.systemGroupedBackground))
        .onChange(of: isRunning) { running in
            if running {
                executionStartTime = Date()
                startTimer()
            } else {
                stopTimer()
            }
        }
        .sheet(isPresented: $showingParameters) {
            executionParametersSheet
        }
    }

    // MARK: - Idle State

    private var idleState: some View {
        VStack(spacing: 16) {
            Image(systemName: "bolt.slash")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            Text("No Recent Activity")
                .font(.headline)
            Text("Run the pipeline to see execution details here.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }

    // MARK: - Header

    private var executionHeader: some View {
        VStack(spacing: 8) {
            Image(systemName: isRunning ? "arrow.triangle.2.circlepath" : "play.circle")
                .font(.system(size: 48))
                .foregroundColor(isRunning ? .blue : .secondary)
                .symbolEffect(.bounce, options: .repeating, value: isRunning)

            Text(isRunning ? "Executing Pipeline..." : "Pipeline Idle")
                .font(.headline)

            Text(connector.name)
                .font(.subheadline)
                .foregroundColor(.secondary)

            if isRunning {
                Text(formatElapsedTime(elapsedTime))
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.blue)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .clipShape(Capsule())
            }

            // Execution Mode Picker
            if !isRunning {
                Picker("Mode", selection: $executionMode) {
                    ForEach(ExecutionMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 32)
                .padding(.top, 8)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(.background)
    }

    // MARK: - Execution Timeline

    private var executionTimeline: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Step-by-Step Progress")
                    .font(.caption.bold())
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(connector.flow.steps.count) steps")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)

            ForEach(Array(connector.flow.steps.enumerated()), id: \.element.id) { index, step in
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(stepColor(for: index))
                            .frame(width: 28, height: 28)
                        Text("\(index + 1)")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(step.type.rawValue.capitalized)
                            .font(.subheadline.bold())
                        if let name = step.config["name"] {
                            Text(name).font(.caption).foregroundColor(.secondary)
                        }
                        if step.type == .delay, let seconds = step.config["seconds"] {
                            Text("Wait \(seconds)s").font(.caption2).foregroundColor(.orange)
                        }
                    }

                    Spacer()

                    stepStatusIndicator(for: index)
                }
                .padding()
                .background(.background)
                .cornerRadius(12)
                .padding(.horizontal)
            }
        }
    }

    // MARK: - Execution History

    private var executionHistory: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Execution History")
                .font(.caption.bold())
                .foregroundColor(.secondary)
                .padding(.horizontal)

            ForEach(recentLogs) { log in
                HStack(spacing: 10) {
                    Circle()
                        .fill(logTypeColor(log.type))
                        .frame(width: 8, height: 8)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(log.message)
                            .font(.subheadline)
                            .lineLimit(2)
                        Text(log.timestamp.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Text(log.type.rawValue.uppercased())
                        .font(.system(size: 9, weight: .bold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(logTypeColor(log.type).opacity(0.15))
                        .foregroundColor(logTypeColor(log.type))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
                .padding()
                .background(.background)
                .cornerRadius(12)
                .padding(.horizontal)
            }
        }
    }

    // MARK: - Stats Card

    private var statsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Execution Statistics")
                .font(.caption.bold())
                .foregroundColor(.secondary)
                .padding(.horizontal)

            HStack(spacing: 16) {
                statItem(label: "Total Runs", value: "\(connector.metadata.executionCount)", color: .blue)
                statItem(label: "Avg Latency", value: String(format: "%.0fms", connector.metadata.averageLatency), color: .purple)
                statItem(label: "Error Rate", value: String(format: "%.1f%%", connector.metadata.errorRate * 100), color: connector.metadata.errorRate > 0.1 ? .red : .green)
            }
            .padding()
            .background(.background)
            .cornerRadius(12)
            .padding(.horizontal)
        }
    }

    // MARK: - Flow Preview

    private var flowPreview: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Flow Pipeline")
                .font(.caption.bold())
                .foregroundColor(.secondary)
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ForEach(Array(connector.flow.steps.enumerated()), id: \.element.id) { index, step in
                        HStack(spacing: 4) {
                            stepIcon(step.type)
                                .font(.caption)
                            Text(step.type.rawValue.capitalized)
                                .font(.caption2)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(stepTypeColor(step.type).opacity(0.1))
                        .foregroundColor(stepTypeColor(step.type))
                        .clipShape(Capsule())

                        if index < connector.flow.steps.count - 1 {
                            Image(systemName: "arrow.right")
                                .font(.system(size: 8))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    // MARK: - Action Bar

    private var actionBar: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                if isRunning {
                    Button {
                        stopTimer()
                    } label: {
                        Text("Cancel")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .bold()
                    }
                } else {
                    Button {
                        showingParameters = true
                    } label: {
                        Image(systemName: "gearshape")
                            .frame(width: 50, height: 50)
                            .background(Color.secondary.opacity(0.15))
                            .foregroundColor(.primary)
                            .cornerRadius(12)
                    }

                    Button {
                        Task {
                            await runtime.run(connector: connector)
                        }
                    } label: {
                        Text("Start Execution")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(connector.flow.steps.isEmpty ? Color.gray : Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .bold()
                    }
                    .disabled(connector.flow.steps.isEmpty)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(.background)
    }

    // MARK: - Parameters Sheet

    private var executionParametersSheet: some View {
        NavigationView {
            Form {
                Section("Execution Mode") {
                    Picker("Mode", selection: $executionMode) {
                        ForEach(ExecutionMode.allCases, id: \.self) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }

                    switch executionMode {
                    case .full:
                        Text("Run the entire pipeline from start to finish.")
                            .font(.caption).foregroundColor(.secondary)
                    case .stepByStep:
                        Text("Pause between each step for manual review.")
                            .font(.caption).foregroundColor(.secondary)
                    case .dryRun:
                        Text("Simulate execution without making real API calls.")
                            .font(.caption).foregroundColor(.secondary)
                    }
                }

                Section("Pipeline Summary") {
                    LabeledContent("Steps", value: "\(connector.flow.steps.count)")
                    LabeledContent("Endpoints", value: "\(connector.endpoints.count)")
                    LabeledContent("Auth Type", value: connector.authConfig.type.rawValue.capitalized)
                }

                Section("Environment") {
                    LabeledContent("Connector", value: connector.name)
                    LabeledContent("Version", value: "v\(connector.version)")
                    LabeledContent("Status", value: connector.status.rawValue.capitalized)
                }
            }
            .navigationTitle("Execution Parameters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { showingParameters = false }
                }
            }
        }
    }

    // MARK: - Helpers

    private func stepColor(for index: Int) -> Color {
        if selectedStepIndex == nil { return .blue }
        guard let selected = selectedStepIndex else { return .secondary }
        if index < selected { return .green }
        if index == selected { return .blue }
        return .secondary
    }

    private func stepStatusIndicator(for index: Int) -> some View {
        Group {
            if let selected = selectedStepIndex {
                if index < selected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                } else if index == selected {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "circle")
                        .foregroundColor(.secondary)
                }
            } else {
                ProgressView()
                    .scaleEffect(0.8)
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
        case .delay: return .gray
        }
    }

    private func statItem(label: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3.bold())
                .foregroundColor(color)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func logTypeColor(_ type: ConnectorLog.LogType) -> Color {
        switch type {
        case .info: return .blue
        case .warning: return .orange
        case .error: return .red
        case .performance: return .purple
        }
    }

    private func formatElapsedTime(_ interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        let ms = Int((interval.truncatingRemainder(dividingBy: 1)) * 100)
        return String(format: "%02d:%02d.%02d", minutes, seconds, ms)
    }

    private func startTimer() {
        elapsedTime = 0
        timer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { _ in
            if let start = executionStartTime {
                elapsedTime = Date().timeIntervalSince(start)
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}
