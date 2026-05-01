import SwiftUI

struct SpacePublishingView: View {
    @StateObject private var publishingManager = SpacePublishingManager.shared
    let space: CollaborationSpace

    @State private var isPublished: Bool = false
    @State private var showReleaseComposer = false
    @State private var releaseVersion = "1.0.0"
    @State private var releaseNotes = ""

    var body: some View {
        List {
            Section(header: Text("Publishing Status")) {
                Toggle("Publicly Published", isOn: Binding(
                    get: { publishingManager.publishedSpaces.contains(space.id) },
                    set: { if $0 { publishingManager.publishSpace(id: space.id) } else { publishingManager.unpublishSpace(id: space.id) } }
                ))

                if publishingManager.publishedSpaces.contains(space.id) {
                    HStack {
                        Text("Public URL")
                        Spacer()
                        Text("tools-kit.app/s/\(space.id.uuidString.prefix(8))")
                            .font(.caption.monospaced())
                            .foregroundColor(.blue)
                    }
                }
            }

            Section(header: Text("Releases")) {
                Button(action: { showReleaseComposer.toggle() }) {
                    Label("Create New Release", systemImage: "tag.fill")
                }

                ForEach(publishingManager.releases[space.id] ?? []) { release in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("v\(release.version)").bold()
                            Spacer()
                            Text(release.timestamp, style: .date).font(.caption)
                        }
                        Text(release.releaseNotes)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("Space Publishing")
        .sheet(isPresented: $showReleaseComposer) {
            NavigationStack {
                Form {
                    TextField("Version (e.g. 1.0.0)", text: $releaseVersion)
                    TextEditor(text: $releaseNotes)
                        .frame(height: 100)

                    Button("Publish Release") {
                        publishingManager.createRelease(spaceID: space.id, version: releaseVersion, notes: releaseNotes, commitID: space.branches.first?.headCommitID ?? UUID())
                        showReleaseComposer = false
                    }
                }
                .navigationTitle("New Release")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { showReleaseComposer = false }
                    }
                }
            }
        }
    }
}
