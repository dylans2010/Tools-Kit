import SwiftUI

// MARK: - Snapshot List

struct WorkspaceSnapshotView: View {
    @StateObject private var service = WorkspaceSnapshotService.shared
    @State private var showingSave = false
    @State private var compareA: WorkspaceSnapshotService.Snapshot?
    @State private var compareB: WorkspaceSnapshotService.Snapshot?
    @State private var showingDiff = false

    var body: some View {
        List {
            Section {
                Button(action: { showingSave = true }) {
                    Label("Save Current Snapshot", systemImage: "camera.fill")
                }
                .foregroundStyle(.blue)
            }

            if service.snapshots.count >= 2 {
                Section {
                    HStack {
                        SnapshotPicker(label: "Before", selection: $compareA, snapshots: service.snapshots)
                        Image(systemName: "arrow.right")
                            .foregroundStyle(.secondary)
                        SnapshotPicker(label: "After", selection: $compareB, snapshots: service.snapshots)
                    }
                    Button("View Diff") {
                        showingDiff = true
                    }
                    .disabled(compareA == nil || compareB == nil)
                } header: {
                    Text("Compare Snapshots")
                }
            }

            Section {
                if service.snapshots.isEmpty {
                    Text("No Snapshots Saved Yet").foregroundStyle(.secondary).font(.caption)
                } else {
                    ForEach(service.snapshots) { snapshot in
                        SnapshotRow(snapshot: snapshot)
                    }
                    .onDelete { offsets in
                        offsets.map { service.snapshots[$0].id }.forEach { service.deleteSnapshot(id: $0) }
                    }
                }
            } header: {
                Text("Saved Snapshots (\(service.snapshots.count))")
            }
        }
        .navigationTitle("Snapshots")
        .sheet(isPresented: $showingSave) {
            SaveSnapshotView()
        }
        .sheet(isPresented: $showingDiff) {
            if let a = compareA, let b = compareB {
                SnapshotDiffView(snapshotA: a, snapshotB: b)
            }
        }
    }
}

// MARK: - Snapshot Row

struct SnapshotRow: View {
    let snapshot: WorkspaceSnapshotService.Snapshot
    @StateObject private var service = WorkspaceSnapshotService.shared
    @State private var showingRestore = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(snapshot.label).font(.subheadline).bold()
                Spacer()
                Text(snapshot.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption2).foregroundStyle(.secondary)
            }
            if !snapshot.notes.isEmpty {
                Text(snapshot.notes).font(.caption).foregroundStyle(.secondary)
            }
            Button("Restore") { showingRestore = true }
                .font(.caption.bold())
                .foregroundStyle(.orange)
        }
        .padding(.vertical, 4)
        .confirmationDialog("Restore '\(snapshot.label)'?", isPresented: $showingRestore, titleVisibility: .visible) {
            Button("Restore", role: .destructive) {
                service.restoreSnapshot(snapshot)
            }
        } message: {
            Text("This will replace the current workspace state.")
        }
    }
}

// MARK: - Save Snapshot

struct SaveSnapshotView: View {
    @StateObject private var service = WorkspaceSnapshotService.shared
    @Environment(\.dismiss) var dismiss
    @State private var label = ""
    @State private var notes = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Label", text: $label)
                    TextField("Notes (Optional)", text: $notes, axis: .vertical)
                        .lineLimit(3...)
                } header: {
                    Text("Snapshot")
                }
            }
            .navigationTitle("Save Snapshot")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        service.saveSnapshot(label: label.isEmpty ? "Snapshot \(Date().formatted(date: .abbreviated, time: .shortened))" : label, notes: notes)
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Snapshot Diff

struct SnapshotDiffView: View {
    let snapshotA: WorkspaceSnapshotService.Snapshot
    let snapshotB: WorkspaceSnapshotService.Snapshot
    @StateObject private var service = WorkspaceSnapshotService.shared
    @Environment(\.dismiss) var dismiss

    private var diffs: [WorkspaceSnapshotService.SnapshotDiff] {
        service.diff(snapshotA: snapshotA, snapshotB: snapshotB)
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Before").font(.caption.bold()).foregroundStyle(.red)
                            Text(snapshotA.label).font(.subheadline)
                            Text(snapshotA.createdAt.formatted(date: .abbreviated, time: .shortened)).font(.caption2).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "arrow.right").foregroundStyle(.secondary)
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text("After").font(.caption.bold()).foregroundStyle(.green)
                            Text(snapshotB.label).font(.subheadline)
                            Text(snapshotB.createdAt.formatted(date: .abbreviated, time: .shortened)).font(.caption2).foregroundStyle(.secondary)
                        }
                    }
                }

                Section {
                    if diffs.isEmpty {
                        Text("No Differences Found.").foregroundStyle(.secondary).font(.caption)
                    } else {
                        ForEach(diffs) { diff in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(diff.field).font(.caption.bold()).foregroundStyle(.secondary)
                                HStack(spacing: 12) {
                                    Text(diff.before)
                                        .font(.subheadline)
                                        .strikethrough(diff.before != diff.after, color: .red)
                                        .foregroundStyle(diff.before != diff.after ? Color.red : Color.primary)
                                    if diff.before != diff.after {
                                        Image(systemName: "arrow.right").font(.caption).foregroundStyle(.secondary)
                                        Text(diff.after).font(.subheadline).foregroundStyle(.green)
                                    }
                                }
                            }
                            .padding(.vertical, 2)
                        }
                    }
                } header: {
                    Text("Changes (\(diffs.count))")
                }
            }
            .navigationTitle("Snapshot Diff")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Snapshot Picker Helper

struct SnapshotPicker: View {
    let label: String
    @Binding var selection: WorkspaceSnapshotService.Snapshot?
    let snapshots: [WorkspaceSnapshotService.Snapshot]

    var body: some View {
        Menu {
            ForEach(snapshots) { (s: WorkspaceSnapshotService.Snapshot) in
                Button(s.label) { selection = s }
            }
        } label: {
            VStack(alignment: .leading, spacing: 2) {
                Text(label).font(.caption.bold()).foregroundStyle(.secondary)
                Text(selection?.label ?? "Select…").font(.subheadline)
            }
            .padding(8)
            .background(Color(uiColor: .secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .frame(maxWidth: .infinity)
    }
}
