import SwiftUI

struct CollaborationHomeView: View {
    @StateObject private var manager = CollaborationManager.shared
    @State private var showingCreateSpace = false
    @State private var showingCommandPalette = false

    private var onlineUsers: Int {
        manager.spaces.reduce(0) { $0 + $1.activeUsers.count }
    }

    private var recentActivity: [ActivityLog] {
        manager.spaces
            .flatMap { $0.activityFeed }
            .sorted { $0.timestamp > $1.timestamp }
            .prefix(15)
            .map { $0 }
    }

    var body: some View {
        List {
            if !manager.spaces.isEmpty {
                Section {
                    HStack(spacing: 16) {
                        statCard(title: "Spaces", value: "\(manager.spaces.count)", icon: "rectangle.stack")
                        statCard(title: "Online", value: "\(onlineUsers)", icon: "person.wave.2")
                        statCard(title: "Activity", value: "\(recentActivity.count)", icon: "chart.line.uptrend.xyaxis")
                    }
                } header: {
                    Label("Overview", systemImage: "chart.bar")
                }
            }

            Section {
                if manager.spaces.isEmpty {
                    ContentUnavailableView(
                        "No Collaboration Spaces",
                        systemImage: "person.2.slash",
                        description: Text("Create a space to start collaborating with your team.")
                    )
                } else {
                    ForEach(manager.spaces) { space in
                        NavigationLink(destination: SpaceDashboardView(spaceID: space.id)) {
                            HStack {
                                Label(space.name, systemImage: space.icon)
                                Spacer()
                                if !space.activeUsers.isEmpty {
                                    HStack(spacing: -6) {
                                        ForEach(space.activeUsers.prefix(3), id: \.self) { user in
                                            Image(systemName: "person.circle.fill")
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    if space.activeUsers.count > 3 {
                                        Text("+\(space.activeUsers.count - 3)")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                    }
                }
            } header: {
                Label("Your Spaces", systemImage: "rectangle.stack")
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
                Label("Tools & Management", systemImage: "wrench")
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
                Label("Automation & Intelligence", systemImage: "sparkles")
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
                Label("Analytics & Tools", systemImage: "chart.xyaxis.line")
            }

            Section {
                if recentActivity.isEmpty {
                    ContentUnavailableView(
                        "No Recent Activity",
                        systemImage: "clock",
                        description: Text("Activity will appear here as team members work.")
                    )
                } else {
                    ForEach(recentActivity) { log in
                        HStack(spacing: 10) {
                            Image(systemName: iconForAction(log.action))
                                .frame(width: 24)
                                .foregroundStyle(.secondary)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(log.action)
                                    .font(.caption)
                                Text("\(log.userName) • \(log.timestamp, style: .relative)")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            } header: {
                Label("Recent Activity", systemImage: "list.bullet.rectangle")
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

    private func statCard(title: String, value: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: icon)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.headline.bold())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func iconForAction(_ action: String) -> String {
        let lower = action.lowercased()
        if lower.contains("comment") { return "bubble.left" }
        if lower.contains("commit") { return "terminal" }
        if lower.contains("merge") { return "arrow.triangle.merge" }
        if lower.contains("review") { return "eye" }
        if lower.contains("update") { return "pencil" }
        if lower.contains("create") { return "plus.circle" }
        return "arrow.right.circle"
    }
}

struct CreateSpaceView: View {
    @Environment(\.dismiss) var dismiss
    @State private var name = ""
    @State private var description = ""
    @State private var visibility: SpaceVisibility = .privateSpace
    @State private var selectedTemplate: SpaceTemplate?
    @State private var showingTemplates = true

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    if showingTemplates {
                        SpaceTemplatePickerView(selectedTemplate: $selectedTemplate)
                            .listRowInsets(EdgeInsets())
                            .listRowBackground(Color.clear)
                            .onChange(of: selectedTemplate?.name) { _, _ in
                                if let template = selectedTemplate {
                                    if name.isEmpty { name = template.name }
                                    if description.isEmpty { description = template.description }
                                    visibility = template.suggestedVisibility
                                }
                            }
                    }
                    Button {
                        withAnimation { showingTemplates.toggle() }
                    } label: {
                        Label(
                            showingTemplates ? "Hide Templates" : "Choose a Template",
                            systemImage: showingTemplates ? "chevron.up" : "rectangle.grid.2x2"
                        )
                    }
                } header: {
                    Label("Start From Template", systemImage: "doc.on.doc.fill")
                }

                Section {
                    TextField("Name", text: $name)
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(2...4)
                } header: {
                    Label("Information", systemImage: "info.circle")
                }

                Section {
                    Picker("Visibility", selection: $visibility) {
                        Label("Private", systemImage: "lock.fill").tag(SpaceVisibility.privateSpace)
                        Label("Shared", systemImage: "person.2.fill").tag(SpaceVisibility.shared)
                        Label("Public", systemImage: "globe").tag(SpaceVisibility.publicSpace)
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Label("Privacy", systemImage: "lock.shield")
                }
            }
            .navigationTitle("New Space")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        let icon = selectedTemplate?.icon ?? "folder.fill.badge.person.crop"
                        let _ = CollaborationManager.shared.createSpace(
                            name: name,
                            description: description,
                            icon: icon,
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
