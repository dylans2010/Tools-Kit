import SwiftUI

struct GitHubStagingAreaView: View {
    @ObservedObject private var gitEngine = GitEngineService.shared
    @State private var commitMessage = ""
    @State private var selectedBranch = "main"

    var body: some View {
        VStack(spacing: 0) {
            List {
                Section("Staged Changes (\(gitEngine.stagedChanges.count))") {
                    if gitEngine.stagedChanges.isEmpty {
                        Text("No files staged for commit.").font(.caption).foregroundStyle(.secondary)
                    } else {
                        ForEach(gitEngine.stagedChanges) { change in
                            HStack {
                                ChangeTypeBadge(type: change.changeType)
                                VStack(alignment: .leading) {
                                    Text(URL(fileURLWithPath: change.filePath).lastPathComponent)
                                        .font(.subheadline.bold())
                                    Text(change.filePath).font(.caption2).foregroundStyle(.secondary)
                                }
                                Spacer()
                                Button {
                                    gitEngine.unstageChange(id: change.id)
                                } label: {
                                    Image(systemName: "minus.circle.fill").foregroundStyle(.red)
                                }
                            }
                        }
                    }
                }

                Section("Commit Details") {
                    TextField("Commit Message", text: $commitMessage)
                    Picker("Target Branch", selection: $selectedBranch) {
                        Text("main").tag("main")
                        Text("feature/mobile-git").tag("feature/mobile-git")
                    }
                }
            }

            VStack(spacing: 12) {
                Button {
                    let commit = gitEngine.buildCommit(message: commitMessage, branch: selectedBranch)
                    gitEngine.enqueueCommit(id: commit.id)
                    commitMessage = ""
                } label: {
                    Text("Commit & Push")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(gitEngine.stagedChanges.isEmpty || commitMessage.isEmpty ? Color.gray : Color.blue)
                        .cornerRadius(12)
                }
                .disabled(gitEngine.stagedChanges.isEmpty || commitMessage.isEmpty)

                Button("Clear Staging Area") {
                    gitEngine.clearStagingArea()
                }
                .font(.caption)
                .foregroundStyle(.red)
            }
            .padding()
            .background(Color(.systemGroupedBackground))
        }
        .navigationTitle("Staging Area")
    }
}

struct ChangeTypeBadge: View {
    let type: GitEngineService.ChangeType

    var body: some View {
        Text(type.rawValue.prefix(1))
            .font(.caption2.bold())
            .foregroundColor(.white)
            .frame(width: 20, height: 20)
            .background(badgeColor)
            .clipShape(Circle())
    }

    private var badgeColor: Color {
        switch type {
        case .added: return .green
        case .modified: return .blue
        case .deleted: return .red
        case .renamed: return .orange
        }
    }
}
