import SwiftUI

struct AgentProgressSessionView: View {
    let prompt: String
    let owner: String
    let repo: String
    let branch: String?

    @State private var sessionId: String?
    @State private var creationError: String?
    @State private var isCreating = true
    @State private var selectedFilePath: String?

    @StateObject private var store = AgentSessionStore.shared
    @Environment(\.openURL) private var openURL

    var body: some View {
        VStack(spacing: 0) {
            if isCreating {
                ProgressView("Initializing Execution Session…")
                    .frame(maxHeight: .infinity)
            } else if let creationError {
                ContentUnavailableView("Failed to Create Task", systemImage: "exclamationmark.triangle", description: Text(creationError))
            } else if let sessionId, let state = store.state(for: sessionId) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        currentStepSection(state)
                        checklistSection(state)
                        timelineSection(state)
                        logConsoleSection(state)
                        diffViewerSection(state)
                        finalOutputSection(state)
                        debugSection(state)
                    }
                    .padding()
                }
            } else {
                ProgressView("Waiting for session initialization…")
                    .frame(maxHeight: .infinity)
            }
        }
        .navigationTitle("Live Progress")
        .task {
            guard sessionId == nil else { return }
            await createTask()
        }
    }

    private func currentStepSection(_ state: AgentSessionState) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Current Step Indicator").font(.headline)
            Text(state.currentStep ?? "Waiting for confirmed status update…")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func timelineSection(_ state: AgentSessionState) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Session Status Timeline").font(.headline)
            ForEach(state.executionEvents.sorted(by: { $0.timestamp < $1.timestamp })) { event in
                HStack(alignment: .top, spacing: 8) {
                    Circle().fill(color(for: event.type)).frame(width: 8, height: 8).padding(.top, 6)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(event.title).font(.subheadline.bold())
                        Text(event.message).font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text(event.timestamp, style: .time).font(.caption2).foregroundStyle(.tertiary)
                }
            }
        }
    }

    private func checklistSection(_ state: AgentSessionState) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Jules Checklist").font(.headline)
            if state.checklist.isEmpty {
                Text("Waiting for Jules to publish checklist steps…")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(state.checklist.sorted(by: { $0.timestamp < $1.timestamp })) { item in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: symbol(for: item.status))
                            .foregroundStyle(color(forChecklist: item.status))
                            .padding(.top, 2)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.title).font(.subheadline.weight(.semibold))
                            Text(item.details).font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(item.timestamp, style: .time).font(.caption2).foregroundStyle(.tertiary)
                    }
                }
            }
        }
    }

    private func logConsoleSection(_ state: AgentSessionState) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Session Log Console").font(.headline)
            ScrollView {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(Array(state.logs.enumerated()), id: \.offset) { _, line in
                        Text(line)
                            .font(.system(.caption, design: .monospaced))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .frame(maxHeight: 200)
            .padding(8)
            .background(Color(uiColor: .secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    private func diffViewerSection(_ state: AgentSessionState) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("File Change Diff Viewer").font(.headline)
            if state.fileOperations.isEmpty {
                Text("No generated file changes yet.").font(.caption).foregroundStyle(.secondary)
            } else {
                Picker("File", selection: Binding(
                    get: { selectedFilePath ?? state.fileOperations.last?.path ?? "" },
                    set: { selectedFilePath = $0 }
                )) {
                    ForEach(state.fileOperations.map(\.path).uniqued(), id: \.self) { path in
                        Text(path).tag(path)
                    }
                }
                .pickerStyle(.menu)

                if let selected = selectedFilePath ?? state.fileOperations.last?.path,
                   let op = state.fileOperations.last(where: { $0.path == selected }) {
                    Text(op.patch ?? op.content ?? "No diff available")
                        .font(.system(.caption, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(8)
                        .background(Color(uiColor: .secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
    }

    private func finalOutputSection(_ state: AgentSessionState) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Final Output Panel").font(.headline)
            if let prURL = state.session?.outputs?.compactMap({ $0.pullRequest?.url }).first,
               let url = URL(string: prURL) {
                Button("Open Pull Request") { openURL(url) }
                    .buttonStyle(.borderedProminent)
            }
            Text(state.finalOutput ?? "Execution in progress…")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            if let error = state.lastError {
                Text(error).font(.caption).foregroundStyle(.red)
            }
        }
    }

    private func debugSection(_ state: AgentSessionState) -> some View {
        Group {
            if UserDefaults.standard.bool(forKey: "agent.framework.debug") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Debug: Framework Processing").font(.headline)
                    Text("Snapshots: \(state.debugSnapshots.count)")
                        .font(.caption)
                    if let latest = state.debugSnapshots.last {
                        Text("Phase: \(latest.frameworkPhase)")
                        Text("State: \(latest.stateTransition)")
                        Text("UI Trigger: \(latest.uiTrigger)")
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
    }

    private func color(for type: AgentExecutionEventType) -> Color {
        switch type {
        case .sessionStarted: return .blue
        case .stepStarted: return .indigo
        case .stepProgress: return .teal
        case .checklistUpdated: return .cyan
        case .logOutput: return .gray
        case .fileGenerated, .fileUpdated: return .orange
        case .gitOperation: return .green
        case .workflowTriggered: return .purple
        case .sessionCompleted: return .mint
        case .sessionFailed: return .red
        }
    }

    private func symbol(for status: String) -> String {
        switch status.lowercased() {
        case "completed", "success", "succeeded", "done":
            return "checkmark.circle.fill"
        case "failed", "error":
            return "xmark.octagon.fill"
        case "pending":
            return "circle.dotted"
        default:
            return "clock.fill"
        }
    }

    private func color(forChecklist status: String) -> Color {
        switch status.lowercased() {
        case "completed", "success", "succeeded", "done":
            return .green
        case "failed", "error":
            return .red
        case "pending":
            return .gray
        default:
            return .blue
        }
    }

    private func createTask() async {
        isCreating = true
        creationError = nil

        do {
            let session = try await AgentSessionFramework.shared.startSession(prompt: prompt, owner: owner, repo: repo, branch: branch)
            await MainActor.run {
                self.sessionId = session.id
                self.isCreating = false
            }
        } catch {
            await MainActor.run {
                self.creationError = error.localizedDescription
                self.isCreating = false
            }
        }
    }
}

private extension Array where Element: Hashable {
    func uniqued() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}
