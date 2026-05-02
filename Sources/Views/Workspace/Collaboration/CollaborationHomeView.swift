import SwiftUI

struct CollaborationHomeView: View {
    @StateObject private var manager = CollaborationManager.shared
    @State private var showingCreateSpace = false

    var body: some View {
        List {
            Section("Your Spaces") {
                if manager.spaces.isEmpty {
                    Text("No collaboration spaces yet.")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(manager.spaces) { space in
                        NavigationLink(destination: SpaceDashboardView(spaceID: space.id)) {
                            Label(space.name, systemImage: space.icon)
                        }
                    }
                }
            }

            Section("Tools & Management") {
                NavigationLink(destination: PullRequestDashboardView()) {
                    Label("Pull Requests", systemImage: "arrow.triangle.pull")
                }
                NavigationLink(destination: ActivityTimelineView()) {
                    Label("Activity Timeline", systemImage: "clock.arrow.2.circlepath")
                }
                NavigationLink(destination: SpacePublishingView()) {
                    Label("Distribution & Publishing", systemImage: "paperplane.fill")
                }
                NavigationLink(destination: WorkspaceCommandCenterView()) {
                    Label("Command Center", systemImage: "terminal.fill")
                }
                NavigationLink(destination: SpaceVersionHistoryView()) {
                    Label("Version History", systemImage: "clock.fill")
                }
            }

            Section("Recent Activity") {
                let recentActivity = manager.spaces.flatMap { $0.activityFeed }.sorted { $0.timestamp > $1.timestamp }.prefix(10)
                if recentActivity.isEmpty {
                    Text("No recent activity.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    ForEach(recentActivity) { log in
                        VStack(alignment: .leading) {
                            Text(log.action)
                                .font(.caption)
                            Text("\(log.userName) • \(log.timestamp, style: .relative)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("Collaboration")
        .toolbar {
            Button(action: { showingCreateSpace = true }) {
                Image(systemName: "plus")
            }
        }
        .sheet(isPresented: $showingCreateSpace) {
            CreateSpaceView()
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
                Section("Information") {
                    TextField("Name", text: $name)
                    TextField("Description", text: $description)
                }

                Section("Privacy") {
                    Picker("Visibility", selection: $visibility) {
                        Text("Private").tag(SpaceVisibility.privateSpace)
                        Text("Shared").tag(SpaceVisibility.shared)
                        Text("Public").tag(SpaceVisibility.publicSpace)
                    }
                    .pickerStyle(.segmented)
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
