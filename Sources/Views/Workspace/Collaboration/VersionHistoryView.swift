import SwiftUI

struct VersionHistoryView: View {
    let spaceID: UUID
    @StateObject private var manager = CollaborationManager.shared

    private var space: CollaborationSpace? {
        manager.spaces.first { $0.id == spaceID }
    }

    var body: some View {
        VStack {
            HStack {
                Text("History")
                    .font(.headline)
                Spacer()
                NavigationLink("Manage Branches") {
                    BranchManagementUI(spaceID: spaceID)
                }
                .font(.subheadline)
            }
            .padding()

            List {
                // Placeholder for commit list
                Text("No commits yet.")
                    .foregroundColor(.secondary)
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
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        if branch.id == space.currentBranchID {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        }
                        if branch.isProtected {
                            Image(systemName: "lock.fill")
                                .font(.caption)
                                .foregroundColor(.orange)
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
