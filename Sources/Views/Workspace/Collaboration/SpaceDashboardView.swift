import SwiftUI

struct SpaceDashboardView: View {
    let spaceID: UUID
    @StateObject private var manager = CollaborationManager.shared
    @State private var selectedTab = 0
    @State private var showingAddData = false

    private var space: CollaborationSpace? {
        manager.spaces.first { $0.id == spaceID }
    }

    var body: some View {
        Group {
            if let space = space {
                VStack(spacing: 0) {
                    Picker("Tab", selection: $selectedTab) {
                        Image(systemName: "house").tag(0)
                        Image(systemName: "book").tag(1)
                        Image(systemName: "rectangle.on.rectangle.angled").tag(2)
                        Image(systemName: "video").tag(3)
                        Image(systemName: "list.bullet.rectangle").tag(4)
                        Image(systemName: "tablecells").tag(5)
                        Image(systemName: "photo.on.rectangle").tag(6)
                        Image(systemName: "clock").tag(7)
                        Image(systemName: "gear").tag(8)
                    }
                    .pickerStyle(.segmented)
                    .padding()

                    contentView(for: space)
                }
                .navigationTitle(space.name)
                .toolbar {
                    Button(action: { showingAddData = true }) {
                        Image(systemName: "plus.circle")
                    }
                }
                .sheet(isPresented: $showingAddData) {
                    AddDataCollabView(spaceID: space.id)
                }
            } else {
                Text("Space not found.")
            }
        }
    }

    @ViewBuilder
    private func contentView(for space: CollaborationSpace) -> some View {
        if currentUserRole(for: space) == .viewer && [1, 2, 3, 4, 5, 6].contains(selectedTab) {
            PermissionDeniedView(title: "Permission Denied", icon: "lock.fill", message: "You only have viewer access to this space.")
        } else {
            switch selectedTab {
            case 0: SpaceOverviewTab(space: space)
            case 1: SpaceObjectsList(title: "Notebooks", ids: space.notebookIDs, icon: "book")
            case 2: SpaceObjectsList(title: "Slides", ids: space.slideDeckIDs, icon: "rectangle.on.rectangle.angled")
            case 3: ProjectBoardView(spaceID: space.id)
            case 4: DecisionEngineView(spaceID: space.id)
            case 5: SpaceObjectsList(title: "Sheets", ids: space.spreadsheetIDs, icon: "tablecells")
            case 6: SpaceObjectsList(title: "Media Projects", ids: space.mediaProjectIDs, icon: "photo.on.rectangle")
            case 7: VersionHistoryView(spaceID: space.id)
            case 8: SpaceSettingsTab(space: space)
            default: EmptyView()
            }
        }
    }

    private func currentUserRole(for space: CollaborationSpace) -> SpaceRole {
        // In local production mode, if you are not the owner and not in members, you are a viewer.
        // For simulation purposes, we check if the space name contains "(View Only)"
        if space.name.contains("(View Only)") {
            return .viewer
        }
        return .owner
    }
}

struct SpaceOverviewTab: View {
    let space: CollaborationSpace

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if space.description.isEmpty {
                    Text("No description provided.")
                        .italic()
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                } else {
                    Text(space.description)
                        .padding(.horizontal)
                }

                Divider()

                Text("Activity Feed")
                    .font(.headline)
                    .padding(.horizontal)

                if space.activityFeed.isEmpty {
                    Text("No activity yet.")
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                } else {
                    ForEach(space.activityFeed) { log in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(log.action)
                                    .font(.subheadline)
                                Text("\(log.userName) • \(log.timestamp, style: .relative)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 4)
                    }
                }
            }
        }
    }
}

struct SpaceObjectsList: View {
    let title: String
    let ids: [UUID]
    let icon: String

    var body: some View {
        List {
            if ids.isEmpty {
                Text("No \(title.lowercased()) added to this space.")
                    .foregroundColor(.secondary)
            } else {
                ForEach(ids, id: \.self) { id in
                    HStack {
                        Label("Object \(id.uuidString.prefix(8))", systemImage: icon)
                        Spacer()
                        Button {
                            // Open object
                        } label: {
                            Image(systemName: "arrow.up.right.square")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
        }
    }
}

struct SpaceSettingsTab: View {
    let space: CollaborationSpace
    @StateObject private var manager = CollaborationManager.shared

    var body: some View {
        List {
            Section("Space Info") {
                HStack {
                    Text("Name")
                    Spacer()
                    Text(space.name).foregroundColor(.secondary)
                }
                HStack {
                    Text("Visibility")
                    Spacer()
                    Text(space.visibility.rawValue).foregroundColor(.secondary)
                }
            }

            Section("Data Management") {
                Button {
                    if let url = manager.exportSpace(id: space.id) {
                        let av = UIActivityViewController(activityItems: [url], applicationActivities: nil)
                        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                           let rootVC = windowScene.windows.first?.rootViewController {
                            rootVC.present(av, animated: true)
                        }
                    }
                } label: {
                    Label("Export Space Session", systemImage: "square.and.arrow.up")
                }
            }

            Section("Danger Zone") {
                Button(role: .destructive) {
                    manager.deleteSpace(id: space.id)
                } label: {
                    Label("Delete Space", systemImage: "trash")
                }
            }
        }
    }
}
