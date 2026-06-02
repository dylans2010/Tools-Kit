import SwiftUI

struct SDKBuildArtifactView: View {
    @ObservedObject var store = DeveloperPersistentStore.shared
    @State private var isBuilding = false

    var body: some View {
        List {
            Section("Continuous Integration") {
                Button(action: { runBuild() }) {
                    HStack {
                        Label("Trigger New Build", systemImage: "hammer.fill")
                        Spacer()
                        if isBuilding {
                            ProgressView()
                        }
                    }
                }
                .disabled(isBuilding)
            }

            Section("Build Artifacts") {
                if store.sdkArtifacts.isEmpty {
                    Text("No build artifacts available.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(store.sdkArtifacts.sorted(by: { $0.createdAt > $1.createdAt })) { artifact in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(artifact.name)
                                    .font(.subheadline.bold())
                                Text("\(artifact.type) • \(formatSize(artifact.sizeBytes))")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Button {
                                // Download action
                            } label: {
                                Image(systemName: "arrow.down.circle.fill")
                                    .font(.title3)
                                    .foregroundStyle(.blue)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.vertical, 4)
                    }
                    .onDelete(perform: deleteArtifact)
                }
            }
        }
        .navigationTitle("Build Artifacts")
    }

    private func runBuild() {
        isBuilding = true
        // Simulate build process
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            let newArtifact = SDKBuildArtifact(
                sdkID: UUID(),
                name: "Build_v1.2.0_\(Int.random(in: 1000...9999))",
                type: ".xcframework",
                sizeBytes: Int64.random(in: 50_000_000...150_000_000)
            )
            var updated = store.sdkArtifacts
            updated.append(newArtifact)
            store.saveSDKArtifacts(updated)
            isBuilding = false
        }
    }

    private func deleteArtifact(at offsets: IndexSet) {
        var updated = store.sdkArtifacts
        updated.remove(atOffsets: offsets)
        store.saveSDKArtifacts(updated)
    }

    private func formatSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}
