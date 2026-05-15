import SwiftUI

struct GitHubCommandCenterView: View {
    @ObservedObject private var gitEngine = GitEngineService.shared
    @State private var currentBranch = "main"
    @State private var isSyncing = false

    var body: some View {
        List {
            Section {
                HStack {
                    Label("Current Branch", systemImage: "arrow.branch")
                    Spacer()
                    Text(currentBranch).bold()
                }

                HStack {
                    Label("Ahead", systemImage: "arrow.up.circle")
                    Spacer()
                    Text("\(gitEngine.commitQueue.count) commits").foregroundStyle(.primary)
                }

                HStack {
                    Label("Behind", systemImage: "arrow.down.circle")
                    Spacer()
                    Text("0 Commits").foregroundStyle(.secondary)
                }
            } header: {
                Text("Repository State")
            }

            Section {
                CommandButton(title: "Fetch & Pull", icon: "arrow.down.to.line", color: .blue) {
                    performSyncAction("Pulling Latest Changes...")
                }

                CommandButton(title: "Push Commits", icon: "arrow.up.to.line", color: .green) {
                    performSyncAction("Pushing Local Commits...")
                }

                CommandButton(title: "Switch Branch", icon: "arrow.left.and.right", color: .purple) {
                    // Branch switching logic
                }
            } header: {
                Text("Sync Operations")
            }

            Section {
                if gitEngine.commitQueue.isEmpty {
                    Text("No Pending Operations").font(.caption).foregroundStyle(.secondary)
                } else {
                    ForEach(gitEngine.commitQueue, id: \.self) { commitID in
                        if let commit = gitEngine.localCommits.first(where: { $0.id == commitID }) {
                            HStack {
                                Image(systemName: "clock.fill").foregroundStyle(.secondary)
                                Text(commit.message).font(.caption)
                                Spacer()
                                Text("Pending").font(.caption2).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            } header: {
                Text("Offline Queue")
            }
        }
        .navigationTitle("Command Center")
        .overlay {
            if isSyncing {
                ProgressView("Syncing...")
                    .padding()
                    .background(Color(uiColor: .systemBackground))
                    .cornerRadius(12)
                    .shadow(radius: 10)
            }
        }
    }

    private func performSyncAction(_ message: String) {
        isSyncing = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isSyncing = false
            // Real API integration would go here
        }
    }
}

struct CommandButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Label(title, systemImage: icon)
                    .foregroundColor(color)
                Spacer()
                Image(systemName: "chevron.right").font(.caption).foregroundStyle(.secondary)
            }
        }
    }
}
