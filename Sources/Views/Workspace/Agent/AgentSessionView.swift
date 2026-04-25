import SwiftUI

struct AgentSessionView: View {
    let sessionId: String
    @StateObject private var sessionManager = AgentSessionManager.shared

    var body: some View {
        VStack(spacing: 0) {
            if let session = sessionManager.activeSessions.first(where: { $0.id == sessionId }),
               let state = sessionManager.sessionStates[sessionId] {

                Picker("Session View", selection: state.$selectedTab) {
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
                            // Header
                            VStack(alignment: .leading, spacing: 8) {
                                Text(session.title ?? "Agent Task")
                                    .font(.title3.bold())
                                Text(session.prompt)
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

                                if let activities = sessionManager.activities[sessionId] {
                                    ForEach(activities) { activity in
                                        ActivityRow(activity: activity)
                                    }
                                } else {
                                    ProgressView()
                                        .padding()
                                }
                            }

                            // Result
                            if let pr = session.outputs?.compactMap({ $0.pullRequest }).first {
                                AgentResultView(pullRequest: pr)
                                    .padding()
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
                ProgressView("Loading session...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationTitle("Session Tracking")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            sessionManager.startPolling(sessionId: sessionId)
        }
        .onDisappear {
            sessionManager.stopPolling(sessionId: sessionId)
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
