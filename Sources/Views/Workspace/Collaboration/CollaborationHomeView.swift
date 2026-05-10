import SwiftUI

struct CollaborationHomeView: View {
    @StateObject private var manager = CollaborationManager.shared
    @State private var showingCreateSpace = false
    @State private var showingCommandPalette = false

    var body: some View {
        List {
            Section {
                if manager.spaces.isEmpty {
                    Text("No Collaboration Spaces Yet")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(manager.spaces) { space in
                        NavigationLink(destination: SpaceDashboardView(spaceID: space.id)) {
                            Label(space.name, systemImage: space.icon)
                        }
                    }
                }
            } header: {
                Text("Your Spaces")
            }

            Section {
                if let firstSpace = manager.spaces.first {
                    NavigationLink(destination: PullRequestDashboardView(spaceID: firstSpace.id)) {
                        Label("Pull Requests", systemImage: "arrow.triangle.pull")
                    }
                } else {
                    Label("Pull Requests", systemImage: "arrow.triangle.pull")
                        .foregroundStyle(.secondary)
                }
                NavigationLink(destination: ActivityTimelineView(spaceID: manager.spaces.first?.id ?? UUID())) {
                    Label("Activity Timeline", systemImage: "clock.arrow.2.circlepath")
                }
                NavigationLink(destination: SpacePublishingView(spaceID: manager.spaces.first?.id ?? UUID())) {
                    Label("Distribution & Publishing", systemImage: "paperplane")
                }
                NavigationLink(destination: WorkspaceCommandCenterView()) {
                    Label("Command Center", systemImage: "terminal")
                }
                NavigationLink(destination: SpaceVersionHistoryView()) {
                    Label("Version History", systemImage: "clock")
                }
            } header: {
                Text("Tools & Management")
            }

            Section {
                NavigationLink(destination: WorkspaceAdvancedHomeView()) {
                    Label("Advanced Workspace", systemImage: "square.3.layers.3d")
                }
                NavigationLink(destination: AdvancedCollaborationView()) {
                    Label("Advanced Collaboration", systemImage: "person.2.wave.2")
                }
                NavigationLink(destination: AutomationHomeView()) {
                    Label("Automations", systemImage: "bolt")
                }
                NavigationLink(destination: ContentGraphView()) {
                    Label("Content Graph", systemImage: "circle.hexagongrid")
                }
                NavigationLink(destination: WorkspaceSnapshotView()) {
                    Label("Snapshots", systemImage: "camera")
                }
                NavigationLink(destination: WorkspaceGlobalSearchView()) {
                    Label("Global Search", systemImage: "magnifyingglass")
                }
            } header: {
                Text("Automation & Intelligence")
            }

            Section {
                NavigationLink(destination: WorkspaceToolsPanelView(spaceID: manager.spaces.first?.id)) {
                    Label("Workspace Tools", systemImage: "wrench.and.screwdriver")
                }
                NavigationLink(destination: CommandHistoryView()) {
                    Label("Command History", systemImage: "clock.arrow.circlepath")
                }
                NavigationLink(destination: PluginsMainView()) {
                    Label("Workspace Extensions", systemImage: "puzzlepiece.extension")
                }
            } header: {
                Text("Analytics & Tools")
            }

            Section {
                let recentActivity = manager.spaces.flatMap { $0.activityFeed }.sorted { $0.timestamp > $1.timestamp }.prefix(10)
                if recentActivity.isEmpty {
                    Text("No Recent Activity")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(recentActivity) { log in
                        VStack(alignment: .leading) {
                            Text(log.action)
                                .font(.caption)
                            Text("\(log.userName) • \(log.timestamp, style: .relative)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            } header: {
                Text("Recent Activity")
            }
        }
        .navigationTitle("Collaboration")
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                CommandPaletteButton(isShowingPalette: $showingCommandPalette)
                Button(action: { showingCreateSpace = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingCreateSpace) {
            CreateSpaceView()
        }
        .overlay {
            if showingCommandPalette {
                GlobalCommandPaletteView(isPresented: $showingCommandPalette, currentView: "collaboration")
                    .ignoresSafeArea()
            }
        }
    }
}

struct CreateSpaceView: View {
    @Environment(\.dismiss) var dismiss
    @State private var name = ""
    @State private var description = ""
    @State private var visibility: SpaceVisibility = .privateSpace

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $name)
                    TextField("Description", text: $description)
                } header: {
                    Text("Information")
                }

                Section {
                    Picker("Visibility", selection: $visibility) {
                        Text("Private").tag(SpaceVisibility.privateSpace)
                        Text("Shared").tag(SpaceVisibility.shared)
                        Text("Public").tag(SpaceVisibility.publicSpace)
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text("Privacy")
                }
            }
            .navigationTitle("New Space")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        let _ = CollaborationManager.shared.createSpace(
                            name: name,
                            description: description,
                            icon: "folder.fill.badge.person.crop",
                            visibility: visibility
                        )
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}
