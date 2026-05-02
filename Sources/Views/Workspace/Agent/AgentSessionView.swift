import SwiftUI
import UIKit

struct AgentSessionView: View {
    let sessionId: String?
    @EnvironmentObject private var systemAgentViewModel: SystemAgentViewModel
    @EnvironmentObject private var julesAgentViewModel: JulesAgentViewModel
    @AppStorage("selectedAgentType") private var selectedAgentType = AgentType.jules.rawValue
    @StateObject private var sessionManager = AgentSessionManager.shared
    @StateObject private var viewModel: AgentSessionViewModel

    init(sessionId: String) {
        self.sessionId = sessionId
        _viewModel = StateObject(wrappedValue: AgentSessionViewModel(sessionId: sessionId))
    }

    init() {
        self.sessionId = nil
        _viewModel = StateObject(wrappedValue: AgentSessionViewModel(sessionId: ""))
    }

    var body: some View {
        VStack(spacing: 0) {
            if sessionId == nil {
                systemChatBody
            } else if let sessionId, let state = sessionManager.sessionStates[sessionId] {
                let session = viewModel.session ?? sessionManager.activeSessions.first(where: { $0.id == sessionId })

                Picker("Session View", selection: Binding(
                    get: { state.selectedTab },
                    set: { state.selectedTab = $0 }
                )) {
                    Text("Log").tag(0)
                    Text("Timeline").tag(1)
                    Text("Tools").tag(2)
                    Text("Memory").tag(3)
                    Text("Diffs").tag(4)
                    Text("Check").tag(5)
                    Text("Work").tag(6)
                }
                .pickerStyle(.segmented)
                .padding()
                .background(Color(.systemBackground))

                Divider()

                switch state.selectedTab {
                case 0:
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            sessionStatusSection

                            // Header
                            VStack(alignment: .leading, spacing: 8) {
                                Text(viewModel.session?.title ?? session?.title ?? "Agent Task")
                                    .font(.title3.bold())
                                Text(viewModel.session?.prompt ?? session?.prompt ?? "")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.secondarySystemBackground))

                            // Activities
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Activity Log")
                                    .font(.headline)
                                    .padding(.horizontal)

                                if !viewModel.activities.isEmpty {
                                    ForEach(viewModel.activities) { activity in
                                        ActivityRow(activity: activity)
                                    }
                                } else if let activities = sessionManager.activities[sessionId] {
                                    ForEach(activities) { activity in
                                        ActivityRow(activity: activity)
                                    }
                                } else {
                                    ProgressView()
                                        .padding()
                                }
                            }

                            // Result
                            if let session,
                               let pr = viewModel.resolvedPullRequest(from: viewModel.session ?? session) {
                                AgentResultView(pullRequest: pr)
                                    .padding()
                            } else if viewModel.isTerminalCompleted {
                                Text("PR not available")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .padding(.horizontal)
                            }
                        }
                    }
                case 1: AgentExecutionTimelineView(state: state)
                case 2: AgentToolExecutionView(state: state)
                case 3: AgentMemoryInspectorView(state: state)
                case 4: AgentDiffViewerView(state: state)
                case 5: AgentCheckpointManagerView(state: state)
                case 6: AgentWorkspaceView(state: state)
                default: EmptyView()
                }
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        sessionStatusSection
                        ProgressView("Loading session…")
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Session Tracking")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if let sessionURL = viewModel.validSessionURL {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Open in Jules") {
                        viewModel.open(url: sessionURL)
                    }
                }
            }
        }
        .onAppear {
            guard let sessionId else { return }
            viewModel.startPolling()
            sessionManager.startPolling(sessionId: sessionId)
        }
        .onDisappear {
            guard let sessionId else { return }
            viewModel.stopPolling()
            sessionManager.stopPolling(sessionId: sessionId)
        }
    }

    private var activeAgentViewModel: any AgentViewModelProtocol {
        selectedAgentType == AgentType.system.rawValue ? systemAgentViewModel : julesAgentViewModel
    }

    private var systemChatBody: some View {
        VStack {
            statusBanner
            List(activeAgentViewModel.messages) { message in
                messageRow(message)
                .listRowSeparator(.hidden)
            }
            .listStyle(.plain)

            HStack(spacing: 8) {
                TextField("Message", text: Binding(
                    get: { activeAgentViewModel.inputText },
                    set: { activeAgentViewModel.inputText = $0 }
                ))
                .textFieldStyle(.roundedBorder)

                Button("Send") {
                    Task {
                        await activeAgentViewModel.submit()
                    }
                }
                .disabled(activeAgentViewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding()
        }
    }

    @ViewBuilder
    private func messageRow(_ message: SystemAgentMessage) -> some View {
        switch message.role {
        case .user:
            HStack {
                Spacer()
                Text(message.content)
                    .padding(10)
                    .background(Color.blue.opacity(0.15))
                    .cornerRadius(8)
            }
        case .assistant, .system:
            HStack {
                Text(message.content)
                    .padding(10)
                    .background(Color.gray.opacity(0.12))
                    .cornerRadius(8)
                Spacer()
            }
        case .toolCall(let name, let input):
            VStack(alignment: .leading, spacing: 8) {
                Label("⚙ Running: \(name)", systemImage: "wrench.and.screwdriver")
                    .font(.subheadline.weight(.semibold))
                DisclosureGroup("Input Parameters") {
                    Text(prettyJSON(from: input.mapValues(\.value)))
                        .font(.system(.caption, design: .monospaced))
                        .padding(.top, 4)
                }
            }
            .padding(10)
            .background(Color.orange.opacity(0.12))
            .cornerRadius(10)
        case .toolResult(let toolName, let result):
            VStack(alignment: .leading, spacing: 8) {
                Label("Tool Result: \(toolName)", systemImage: "terminal")
                    .font(.subheadline.weight(.semibold))
                DisclosureGroup("Output") {
                    Text(prettyCodeBlock(result))
                        .font(.system(.caption, design: .monospaced))
                        .padding(.top, 4)
                }
            }
            .padding(10)
            .background(Color.green.opacity(0.12))
            .cornerRadius(10)
        case .failed(let message):
            VStack(alignment: .leading, spacing: 10) {
                Label("Execution Failed", systemImage: "xmark.octagon.fill")
                    .foregroundStyle(.red)
                Text(message)
                    .font(.subheadline)
                Button("Retry") {
                    Task {
                        if let vm = activeAgentViewModel as? SystemAgentViewModel {
                            await vm.retryLastSubmission()
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(10)
            .background(Color.red.opacity(0.12))
            .cornerRadius(10)
        }
    }

    private var statusBanner: some View {
        Group {
            switch activeAgentViewModel.state {
            case .thinking:
                Label("Thinking…", systemImage: "brain")
            case .executingTool(let name):
                Label("Running \(name)…", systemImage: "gearshape.2")
            case .responding:
                Label("Writing response…", systemImage: "text.bubble")
            case .completed:
                Label("Completed", systemImage: "checkmark.circle")
            case .failed(let error):
                Label(error.localizedDescription, systemImage: "xmark.circle")
                    .foregroundStyle(.red)
            case .idle:
                EmptyView()
            }
        }
        .font(.caption)
        .padding(.top, 8)
    }

    private func prettyJSON(from object: [String: Any]) -> String {
        guard JSONSerialization.isValidJSONObject(object),
              let data = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .sortedKeys]),
              let string = String(data: data, encoding: .utf8) else {
            return String(describing: object)
        }
        return string
    }

    private func prettyCodeBlock(_ value: String) -> String {
        guard let data = value.data(using: .utf8),
              let object = try? JSONSerialization.jsonObject(with: data),
              JSONSerialization.isValidJSONObject(object),
              let prettyData = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .sortedKeys]),
              let pretty = String(data: prettyData, encoding: .utf8) else {
            return value
        }
        return pretty
    }

    private var sessionStatusSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Session Status")
                .font(.headline)

            switch viewModel.uiStatus {
            case .pending, .running:
                HStack(spacing: 8) {
                    ProgressView()
                    Text(viewModel.uiStatus == .pending ? "Pending…" : "Running…")
                        .font(.subheadline)
                }
            case .completed:
                Label("Completed", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            case .failed:
                Label("Failed", systemImage: "xmark.octagon.fill")
                    .foregroundStyle(.red)
            }

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            if viewModel.isTerminalCompleted {
                if let prURL = viewModel.validPRURL {
                    Button("Open PR") {
                        viewModel.open(url: prURL)
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    Text("PR not available")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
    }
}

@MainActor
final class AgentSessionViewModel: ObservableObject {
    enum UIStatus {
        case pending
        case running
        case completed
        case failed
    }

    @Published private(set) var session: AgentSession?
    @Published private(set) var activities: [AgentActivity] = []
    @Published private(set) var errorMessage: String?

    let sessionId: String

    private let client = AgentClient.shared
    private var pollTask: Task<Void, Never>?
    private let openURL: (URL) -> Void

    init(sessionId: String, openURL: (@escaping (URL) -> Void)? = nil) {
        self.sessionId = sessionId
        self.openURL = openURL ?? { url in
            Task { @MainActor in
                UIApplication.shared.open(url)
            }
        }
    }

    var uiStatus: UIStatus {
        guard let raw = session?.status?.lowercased() else {
            return session == nil ? .pending : .running
        }

        if ["completed", "succeeded", "success", "done"].contains(raw) {
            return .completed
        }
        if ["failed", "error", "cancelled"].contains(raw) {
            return .failed
        }
        if ["pending", "queued", "created"].contains(raw) {
            return .pending
        }
        return .running
    }

    var isTerminalCompleted: Bool {
        uiStatus == .completed
    }

    var validSessionURL: URL? {
        guard let source = session?.sessionURL?.trimmingCharacters(in: .whitespacesAndNewlines), !source.isEmpty,
              let url = URL(string: source) else {
            return nil
        }
        return url
    }

    var validPRURL: URL? {
        guard let candidate = prURLString?.trimmingCharacters(in: .whitespacesAndNewlines),
              let url = URL(string: candidate),
              url.scheme == "https",
              url.host == "github.com" else {
            return nil
        }
        return url
    }

    func startPolling() {
        guard pollTask == nil else { return }
        pollTask = Task {
            while !Task.isCancelled {
                await refresh()
                if isTerminalState { break }
                try? await Task.sleep(for: .seconds(5))
            }
            pollTask = nil
        }
    }

    func stopPolling() {
        pollTask?.cancel()
        pollTask = nil
    }

    func open(url: URL) {
        openURL(url)
    }

    func resolvedPullRequest(from session: AgentSession) -> AgentPullRequest? {
        session.outputs?.compactMap(\.pullRequest).first
    }

    private var prURLString: String? {
        if let nested = session?.outputs?.compactMap({ $0.pullRequest?.url }).first(where: { !$0.isEmpty }) {
            return nested
        }
        return session?.outputs?.compactMap({ $0.prURL }).first(where: { !$0.isEmpty })
    }

    private var isTerminalState: Bool {
        uiStatus == .completed || uiStatus == .failed
    }

    private func refresh() async {
        do {
            async let sessionRequest = client.getSession(id: sessionId)
            async let activityRequest = client.fetchActivities(sessionId: sessionId)

            let (updatedSession, updatedActivities) = try await (sessionRequest, activityRequest)
            session = updatedSession
            activities = updatedActivities
            errorMessage = nil
            AgentSessionStore.shared.upsertSession(updatedSession, workspaceId: updatedSession.sourceContext.source)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

struct ActivityRow: View {
    let activity: AgentActivity

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(color(for: activity))
                .frame(width: 10, height: 10)
                .padding(.top, 6)

            VStack(alignment: .leading, spacing: 4) {
                Text(title(for: activity))
                    .font(.subheadline.bold())
                if let desc = description(for: activity) {
                    Text(desc)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Text(activity.createTime, style: .time)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            Spacer()
        }
        .padding(.horizontal)
    }

    private func color(for activity: AgentActivity) -> Color {
        if activity.sessionCompleted != nil { return .green }
        if activity.planGenerated != nil { return .blue }
        return .orange
    }

    private func title(for activity: AgentActivity) -> String {
        if let plan = activity.planGenerated {
            return "Plan Generated"
        } else if let progress = activity.progressUpdated {
            return progress.title ?? "Updating Progress"
        } else if activity.sessionCompleted != nil {
            return "Task Completed"
        }
        return "Thinking..."
    }

    private func description(for activity: AgentActivity) -> String? {
        if let plan = activity.planGenerated {
            return "\(plan.plan.steps.count) steps planned."
        } else if let progress = activity.progressUpdated {
            return progress.description
        }
        return nil
    }
}
