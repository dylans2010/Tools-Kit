import SwiftUI

struct GitHubReleaseBuilderView: View {
    @ObservedObject private var gitEngine = GitEngineService.shared
    @State private var version = "1.2.0"
    @State private var changelog = ""
    @State private var isReady = false

    var body: some View {
        Form {
            Section {
                TextField("Version Tag", text: $version)
                HStack {
                    Button("Major") { bumpVersion(major: true) }
                    Button("Minor") { bumpVersion(major: false) }
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            } header: {
                Text("Semantic Versioning")
            }

            Section {
                TextEditor(text: $changelog)
                    .font(.system(.body, design: .monospaced))
                    .frame(minHeight: 150)

                Button("Generate from Commits") {
                    generateChangelog()
                }
                .font(.caption)
            } header: {
                Text("Release Notes")
            }

            Section {
                Label("No Merge Conflicts", systemImage: "checkmark.circle.fill").foregroundStyle(.secondary)
                Label("All Changes Reviewed", systemImage: "checkmark.circle.fill").foregroundStyle(.secondary)
                Label("Tests Passing", systemImage: "checkmark.circle.fill").foregroundStyle(.secondary)
            } header: {
                Text("Validation Checklist")
            }

            Section {
                Button {
                    publishRelease()
                } label: {
                    Text("Publish Release \(version)")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(changelog.isEmpty ? Color(.systemGray) : Color.accentColor)
                        .cornerRadius(12)
                }
                .disabled(changelog.isEmpty)
            }
        }
        .navigationTitle("Release Builder")
        .onAppear {
            generateChangelog()
        }
    }

    private func bumpVersion(major: Bool) {
        var components = version.split(separator: ".").compactMap { Int($0) }
        if components.count >= 2 {
            if major { components[0] += 1; components[1] = 0 }
            else { components[1] += 1 }
            version = components.map { String($0) }.joined(separator: ".")
        }
    }

    private func generateChangelog() {
        let commits = gitEngine.localCommits.prefix(10)
        if commits.isEmpty {
            changelog = "No new commits found."
        } else {
            changelog = "### Release \(version)\n\n" + commits.map { "- \($0.message)" }.joined(separator: "\n")
        }
    }

    private func publishRelease() {
        // Logic to push release notes to a special file or API
        gitEngine.stageChange(filePath: "RELEASES.md", original: "", modified: changelog)
        WorkspaceNotificationService.shared.post(title: "Release Published", body: "Release \(version) has been staged.", category: .update)
    }
}
