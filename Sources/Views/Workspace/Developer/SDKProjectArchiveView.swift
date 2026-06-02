import SwiftUI

struct SDKProjectArchiveView: View {
    @ObservedObject var store = DeveloperPersistentStore.shared
    @State private var showingCreateArchive = false
    @State private var newArchiveName = ""

    var body: some View {
        List {
            Section {
                Button(action: { showingCreateArchive = true }) {
                    Label("Archive Current Workspace", systemImage: "archivebox.fill")
                }
            }

            Section("Archived Snapshots") {
                if store.sdkArchives.isEmpty {
                    Text("No archives found.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(store.sdkArchives) { archive in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(archive.name)
                                    .font(.subheadline.bold())
                                Text("\(archive.date, style: .date) • \(archive.size)")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Menu {
                                Button("Restore Snapshot") {}
                                Button(role: .destructive) { deleteArchive(archive) } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            } label: {
                                Image(systemName: "ellipsis.circle")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Project Archive")
        .sheet(isPresented: $showingCreateArchive) {
            NavigationStack {
                Form {
                    TextField("Archive Name", text: $newArchiveName)
                }
                .navigationTitle("New Archive")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancel") { showingCreateArchive = false } }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Archive") { saveArchive() }
                        .disabled(newArchiveName.isEmpty)
                    }
                }
            }
        }
    }

    private func saveArchive() {
        let new = SDKArchive(name: newArchiveName, size: "450 MB")
        var updated = store.sdkArchives
        updated.append(new)
        store.saveSDKArchives(updated)
        newArchiveName = ""
        showingCreateArchive = false
    }

    private func deleteArchive(_ archive: SDKArchive) {
        var updated = store.sdkArchives
        updated.removeAll { $0.id == archive.id }
        store.saveSDKArchives(updated)
    }
}
