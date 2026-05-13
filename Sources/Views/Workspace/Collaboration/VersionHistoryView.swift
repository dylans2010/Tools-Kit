import SwiftUI

struct SpaceVersionHistoryView: View {
    var spaceID: UUID?
    @StateObject private var manager = CollaborationManager.shared

    private var space: CollaborationSpace? {
        guard let spaceID else { return nil }
        return manager.spaces.first { $0.id == spaceID }
    }

    var body: some View {
        VStack {
            HStack {
                Text("History")
                    .font(.headline)
                Spacer()
                if let spaceID {
                    NavigationLink("Manage Branches") {
                        BranchManagementUI(spaceID: spaceID)
                    }
                    .font(.subheadline)
                }
            }
            .padding()

            let history = manager.getCommitHistory(branchID: space?.currentBranchID ?? UUID())
            if history.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text("No Version History Yet")
                        .font(.headline)
                    Text("Every change you make will appear here as a commit.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(history) { commit in
                        VStack(alignment: .leading) {
                            Text(commit.message)
                                .font(.headline)
                            Text("\(commit.author) • \(commit.timestamp, style: .date) At \(commit.timestamp, style: .time)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(commit.id.uuidString.prefix(8))
                                .font(.system(.caption, design: .monospaced))
                                .foregroundStyle(.primary)
                        }
                        .swipeActions {
                            if let spaceID {
                                Button("Revert") {
                                    manager.revertToCommit(spaceID: spaceID, branchID: space?.currentBranchID ?? UUID(), commitID: commit.id)
                                }
                                .tint(.orange)
                            }
                        }
                    }
                }
            }
        }
    }
}

struct BranchManagementUI: View {
    let spaceID: UUID
    @StateObject private var manager = CollaborationManager.shared
    @State private var showingCreateBranch = false

    private var space: CollaborationSpace? {
        manager.spaces.first { $0.id == spaceID }
    }

    var body: some View {
        List {
            if let space = space {
                ForEach(space.branches) { branch in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(branch.name)
                                .font(.headline)
                            Text("Head: \(branch.headCommitID.uuidString.prefix(8))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if branch.id == space.currentBranchID {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.primary)
                        }
                        if branch.isProtected {
                            Image(systemName: "lock.fill")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("Branches")
        .toolbar {
            Button("New Branch") { showingCreateBranch = true }
        }
        .sheet(isPresented: $showingCreateBranch) {
            // Simple branch creation modal
        }
    }
}
