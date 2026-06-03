import SwiftUI

struct BuildArtifactStoreView: View {
    @ObservedObject var store = DeveloperPersistentStore.shared

    var body: some View {
        List {
            Section("Recent Build Artifacts") {
                if store.buildArtifacts.isEmpty {
                    Text("No build artifacts available.").font(.caption).foregroundStyle(.secondary)
                } else {
                    ForEach(store.buildArtifacts) { artifact in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(artifact.filename).font(.subheadline.bold())
                                Text("v\(artifact.version) (\(artifact.build)) • \(artifact.size)").font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Button { } label: {
                                Image(systemName: "icloud.and.arrow.down")
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }

            Section {
                Button { } label: {
                    Label("Upload External Artifact", systemImage: "arrow.up.doc")
                }
            }
        }
        .navigationTitle("Build Store")
        .onAppear {
            if store.buildArtifacts.isEmpty {
                store.saveBuildArtifacts([
                    BuildArtifact(version: "1.2.0", build: "450", filename: "CoreApp_1.2.0_450.ipa", size: "84MB"),
                    BuildArtifact(version: "1.2.0", build: "449", filename: "CoreApp_1.2.0_449.ipa", size: "84MB")
                ])
            }
        }
    }
}
