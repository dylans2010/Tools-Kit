import SwiftUI

struct AgentHomeView: View {
    @StateObject private var sessionManager = AgentSessionManager.shared
    @State private var showingNewTask = false
    @State private var showingSettings = false

    let owner: String
    let repo: String

    var body: some View {
        List {
            if sessionManager.activeSessions.isEmpty && !sessionManager.isLoading {
                ContentUnavailableView(
                    "No Agent Tasks",
                    systemImage: "sparkles",
                    description: Text("Delegate repository tasks to the AI agent.")
                )
            } else {
                ForEach(sessionManager.activeSessions) { session in
                    NavigationLink(destination: AgentSessionView(sessionId: session.id)) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(session.title ?? session.prompt)
                                .font(.headline)
                                .lineLimit(1)
                            Text(session.id)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .listStyle(.plain)
        .navigationTitle("Agent Mode")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingNewTask = true
                } label: {
                    Image(systemName: "plus")
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingSettings = true
                } label: {
                    Image(systemName: "gearshape")
                }
            }
        }
        .sheet(isPresented: $showingNewTask) {
            AgentPromptView(owner: owner, repo: repo)
        }
        .sheet(isPresented: $showingSettings) {
            AgentSettingsView()
        }
        .task {
            await sessionManager.fetchSessions()
        }
    }
}
