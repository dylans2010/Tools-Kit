import SwiftUI

struct TimeTravelHomeView: View {
    @StateObject private var manager = TimeTravelManager.shared
    @State private var selectedEntityFilter: String = "All"
    @State private var showingRestoreConfirmation = false
    @State private var snapshotToRestore: WorkspaceSnapshot?

    private let entityFilters = ["All", "Note", "Task", "Calendar", "File", "Project"]

    private var filteredSnapshots: [WorkspaceSnapshot] {
        let sorted = manager.snapshots.sorted { $0.timestamp > $1.timestamp }
        if selectedEntityFilter == "All" {
            return sorted
        }
        return sorted.filter { $0.entityType.localizedCaseInsensitiveContains(selectedEntityFilter) }
    }

    var body: some View {
        List {
            Section {
                LabeledContent {
                    Text("\(manager.snapshots.count)")
                        .font(.headline)
                } label: {
                    Label("Total Snapshots", systemImage: "clock.arrow.circlepath")
                }
                LabeledContent {
                    Text(entityTypesSummary)
                        .font(.caption)
                } label: {
                    Label("Entity Types", systemImage: "square.stack.3d.up")
                }
                if let latest = manager.snapshots.max(by: { $0.timestamp < $1.timestamp }) {
                    LabeledContent {
                        Text(latest.timestamp, style: .relative)
                            .font(.caption)
                    } label: {
                        Label("Last Snapshot", systemImage: "clock")
                    }
                }
            } header: {
                Label("Overview", systemImage: "chart.bar")
            }

            Section {
                Picker("Filter", selection: $selectedEntityFilter) {
                    ForEach(entityFilters, id: \.self) { filter in
                        Text(filter).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
            } header: {
                Label("Filter", systemImage: "line.3.horizontal.decrease")
            }

            Section {
                if filteredSnapshots.isEmpty {
                    ContentUnavailableView(
                        "No Snapshots",
                        systemImage: "clock.badge.questionmark",
                        description: Text("Workspace changes will appear here automatically.")
                    )
                } else {
                    ForEach(filteredSnapshots) { snapshot in
                        NavigationLink(destination: SnapshotDetailView(snapshot: snapshot)) {
                            HStack {
                                Image(systemName: iconForEntity(snapshot.entityType))
                                    .frame(width: 28)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(snapshot.message)
                                        .font(.subheadline.bold())
                                    HStack(spacing: 6) {
                                        Text(snapshot.entityType)
                                            .font(.caption2)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 1)
                                            .background(.secondary.opacity(0.1), in: Capsule())
                                        Text(snapshot.timestamp, style: .relative)
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                    }
                }
            } header: {
                Label("Activity Timeline", systemImage: "timeline.selection")
            }

            Section {
                Button {
                    manager.takeSnapshot(message: "Manual snapshot")
                } label: {
                    Label("Create Manual Snapshot", systemImage: "camera")
                }

                Button {
                    manager.refresh()
                } label: {
                    Label("Refresh Timeline", systemImage: "arrow.clockwise")
                }
            } header: {
                Label("Actions", systemImage: "bolt")
            }
        }
        .navigationTitle("Time Travel")
        .onAppear {
            manager.refresh()
        }
        .alert("Restore Snapshot?", isPresented: $showingRestoreConfirmation) {
            Button("Restore", role: .destructive) {
                if let snapshot = snapshotToRestore {
                    manager.restore(snapshot)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            if let snapshot = snapshotToRestore {
                Text("This will revert \(snapshot.entityType) to the state at \(snapshot.timestamp.formatted()).")
            }
        }
    }

    private var entityTypesSummary: String {
        let types = Set(manager.snapshots.map(\.entityType))
        return types.sorted().joined(separator: ", ")
    }

    private func iconForEntity(_ type: String) -> String {
        switch type.lowercased() {
        case "note": return "note.text"
        case "task": return "checklist"
        case "calendar": return "calendar"
        case "file": return "doc"
        case "project": return "folder"
        default: return "clock"
        }
    }
}

struct SnapshotDetailView: View {
    let snapshot: WorkspaceSnapshot
    @StateObject private var manager = TimeTravelManager.shared
    @State private var showingConfirmation = false

    var body: some View {
        List {
            Section {
                LabeledContent("Message", value: snapshot.message)
                LabeledContent("Entity Type", value: snapshot.entityType)
                LabeledContent("Date", value: snapshot.timestamp.formatted(date: .complete, time: .standard))
                LabeledContent("Snapshot ID", value: snapshot.id.uuidString.prefix(8).uppercased())
            } header: {
                Label("Details", systemImage: "info.circle")
            }

            Section {
                Button {
                    showingConfirmation = true
                } label: {
                    Label("Restore This State", systemImage: "arrow.uturn.backward")
                }
                .buttonStyle(.borderedProminent)
            } header: {
                Label("Actions", systemImage: "bolt")
            }
        }
        .navigationTitle("Snapshot Details")
        .alert("Restore Snapshot?", isPresented: $showingConfirmation) {
            Button("Restore", role: .destructive) {
                manager.restore(snapshot)
            }
            Button("Cancel", role: .cancel) { }
        }
    }
}
