import SwiftUI

struct CollaborationHomeView: View {
    @StateObject private var manager = CollaborationManager.shared
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    @State private var selectedWorkspaceID: UUID?
    @State private var selectedChannelID: UUID?
    @State private var showingThread = false
    @State private var activeThreadMessage: CollaborationMessage?

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            // Workspace Sidebar
            WorkspaceSidebar(
                workspaces: manager.workspaces,
                selectedWorkspaceID: $selectedWorkspaceID
            )
            .navigationTitle("Workspaces")
        } content: {
            // Channel List
            if let workspace = manager.workspaces.first(where: { $0.id == (selectedWorkspaceID ?? manager.activeWorkspaceID) }) {
                ChannelSidebar(
                    workspace: workspace,
                    selectedChannelID: $selectedChannelID
                )
                .navigationTitle(workspace.name)
            } else {
                Text("Select a Workspace").foregroundStyle(.secondary)
            }
        } detail: {
            // Main Chat / Thread
            if let workspace = manager.workspaces.first(where: { $0.id == (selectedWorkspaceID ?? manager.activeWorkspaceID) }),
               let channel = workspace.channels.first(where: { $0.id == (selectedChannelID ?? manager.activeChannelID) }) {

                HStack(spacing: 0) {
                    CollaborationChatView(
                        workspace: workspace,
                        channel: channel,
                        onOpenThread: { message in
                            activeThreadMessage = message
                            showingThread = true
                        }
                    )

                    if showingThread, let message = activeThreadMessage {
                        Divider()
                        CollaborationThreadView(
                            workspace: workspace,
                            channel: channel,
                            parentMessage: message,
                            onClose: { showingThread = false }
                        )
                        .frame(width: 400)
                        .transition(.move(edge: .trailing))
                    }
                }
                .animation(.spring(), value: showingThread)
            } else {
                Text("Select a Channel").foregroundStyle(.secondary)
            }
        }
        .onAppear {
            selectedWorkspaceID = manager.activeWorkspaceID
            selectedChannelID = manager.activeChannelID
        }
    }
}

private struct WorkspaceSidebar: View {
    let workspaces: [CollaborationWorkspace]
    @Binding var selectedWorkspaceID: UUID?

    var body: some View {
        List(workspaces, selection: $selectedWorkspaceID) { workspace in
            NavigationLink(value: workspace.id) {
                Label(workspace.name, systemImage: workspace.icon)
                    .font(.headline)
            }
        }
        .listStyle(.sidebar)
    }
}

private struct ChannelSidebar: View {
    let workspace: CollaborationWorkspace
    @Binding var selectedChannelID: UUID?

    var body: some View {
        List(selection: $selectedChannelID) {
            Section("Channels") {
                ForEach(workspace.channels.filter { $0.type != .directMessage }) { channel in
                    NavigationLink(value: channel.id) {
                        Label(channel.name, systemImage: channel.type == .privateChannel ? "lock.fill" : "hash")
                    }
                }
            }

            Section("Direct Messages") {
                ForEach(workspace.channels.filter { $0.type == .directMessage }) { dm in
                    NavigationLink(value: dm.id) {
                        Label(dm.name, systemImage: "person.circle")
                    }
                }
            }

            Section("Tools") {
                NavigationLink(destination: PullRequestDashboardView(spaceID: workspace.id)) {
                    Label("Pull Requests", systemImage: "arrow.triangle.pull")
                }
                NavigationLink(destination: WorkspaceCommandCenterView()) {
                    Label("Command Center", systemImage: "terminal")
                }
                NavigationLink(destination: WorkspaceSnapshotView()) {
                    Label("Snapshots", systemImage: "camera")
                }
                NavigationLink(destination: AutomationHomeView()) {
                    Label("Automations", systemImage: "bolt")
                }
                NavigationLink(destination: ContentGraphView()) {
                    Label("Content Graph", systemImage: "circle.hexagongrid")
                }
                NavigationLink(destination: SpaceVersionHistoryView()) {
                    Label("Version History", systemImage: "clock")
                }
            }
        }
        .listStyle(.sidebar)
    }
}
