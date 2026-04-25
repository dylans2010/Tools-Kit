import SwiftUI

struct AgentProgressSessionView: View {
    let prompt: String
    let owner: String
    let repo: String
    let branch: String?

    @State private var session: AgentSession?
    @State private var creationError: String?
    @State private var isCreating = true

    @StateObject private var sessionManager = AgentSessionManager.shared
    @Environment(\.dismiss) var dismiss
    @Environment(\.openURL) var openURL

    var body: some View {
        VStack(spacing: 0) {
            if isCreating {
                VStack(spacing: 20) {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("Initializing Jules Agent...")
                        .font(.headline)
                    Text("Creating a new task for \(owner)/\(repo)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxHeight: .infinity)
            } else if let error = creationError {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.largeTitle)
                        .foregroundColor(.red)
                    Text("Failed to Create Task")
                        .font(.title2.bold())
                    Text(error)
                        .multilineTextAlignment(.center)
                        .padding()
                    Button("Try Again") {
                        createTask()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxHeight: .infinity)
            } else if let currentSession = sessionManager.activeSessions.first(where: { $0.id == session?.id }),
                      let state = sessionManager.sessionStates[currentSession.id] {

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
                    List {
                        // Header Section
                        VStack(alignment: .leading, spacing: 8) {
                            Text(currentSession.title ?? "Agent Task")
                                .font(.title3.bold())
                            Text(currentSession.prompt)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical)
                        .listRowSeparator(.hidden)

                        // Completion Section
                        if let pr = currentSession.outputs?.compactMap({ $0.pullRequest }).first {
                            VStack(spacing: 16) {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                        .font(.title3)
                                    Text("Task Created Successfully!")
                                        .font(.headline)
                                }

                                Button(action: {
                                    if let url = URL(string: pr.url) {
                                        openURL(url)
                                    }
                                }) {
                                    HStack {
                                        Image(systemName: "arrow.up.forward.circle.fill")
                                        Text("Open Pull Request")
                                    }
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                                }
                            }
                            .padding()
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(16)
                            .listRowSeparator(.hidden)
                        }

                        // Activity Log Section
                        Section("Activity Log") {
                            if let activities = sessionManager.activities[currentSession.id] {
                                ForEach(activities) { activity in
                                    ActivityRow(activity: activity)
                                }
                            } else {
                                ProgressView("Fetching activities...")
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding()
                            }
                        }
                    }
                    .listStyle(.plain)
                    .refreshable {
                        await sessionManager.refreshSession(sessionId: currentSession.id)
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
                ProgressView("Loading session details...")
                    .frame(maxHeight: .infinity)
            }
        }
        .navigationTitle("Live Progress")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if session == nil {
                createTask()
            }
        }
    }

    private func createTask() {
        isCreating = true
        creationError = nil

        Task {
            do {
                let newSession = try await AgentSessionManager.shared.startSession(prompt: prompt, owner: owner, repo: repo, branch: branch)
                await MainActor.run {
                    self.session = newSession
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
}
