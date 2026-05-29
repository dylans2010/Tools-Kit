import SwiftUI

struct DeveloperReleaseManagementView: View {
    @ObservedObject var store = DeveloperPersistentStore.shared
    @State private var showingAddRelease = false
    @State private var version = ""
    @State private var build = ""
    @State private var notes = ""

    var body: some View {
        List {
            Section("Active Releases") {
                if store.releases.isEmpty {
                    Text("No releases yet. Start by uploading a build.").font(.caption).foregroundStyle(.secondary)
                } else {
                    ForEach(store.releases) { release in
                        HStack {
                            VStack(alignment: .leading) {
                                Text("v\(release.version) (\(release.buildNumber))").font(.subheadline.bold())
                                Text(release.releaseNotes).font(.caption).lineLimit(1).foregroundStyle(.secondary)
                            }
                            Spacer()
                            statusBadge(release.status)
                        }
                    }
                    .onDelete(perform: deleteRelease)
                }
            }
        }
        .navigationTitle("Release Management")
        .toolbar {
            Button { showingAddRelease = true } label: { Image(systemName: "plus") }
        }
        .sheet(isPresented: $showingAddRelease) {
            NavigationStack {
                Form {
                    TextField("Version", text: $version)
                    TextField("Build Number", text: $build)
                    TextEditor(text: $notes).frame(height: 100)
                }
                .navigationTitle("New Release")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancel") { showingAddRelease = false } }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Create") { addRelease() }
                            .disabled(version.isEmpty || build.isEmpty)
                    }
                }
            }
        }
    }

    private func statusBadge(_ status: ReleaseStatus) -> some View {
        Text(status.rawValue).font(.caption2.bold())
            .padding(.horizontal, 8).padding(.vertical, 4)
            .background(Color.blue.opacity(0.1), in: Capsule())
            .foregroundStyle(.blue)
    }

    private func addRelease() {
        let release = AppRelease(version: version, buildNumber: build, status: .preparing, releaseNotes: notes)
        var current = store.releases
        current.insert(release, at: 0)
        store.saveReleases(current)
        showingAddRelease = false
        version = ""
        build = ""
        notes = ""
    }

    private func deleteRelease(at offsets: IndexSet) {
        var current = store.releases
        current.remove(atOffsets: offsets)
        store.saveReleases(current)
    }
}
