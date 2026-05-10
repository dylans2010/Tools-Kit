import SwiftUI

struct GitHubChangeReviewerView: View {
    @ObservedObject private var gitEngine = GitEngineService.shared
    @State private var approvedFiles: Set<UUID> = []
    @State private var showingCommitSheet = false

    var body: some View {
        VStack(spacing: 0) {
            List {
                Section(header: Text("Review Changes (\(approvedFiles.count)/\(gitEngine.stagedChanges.count))"), footer: Text("All files must be reviewed and approved before committing.")) {
                    if gitEngine.stagedChanges.isEmpty {
                        Text("No staged changes to review.").font(.caption).foregroundStyle(.secondary)
                    } else {
                        ForEach(gitEngine.stagedChanges) { change in
                            NavigationLink {
                                ReviewFileDetailView(change: change, isApproved: approvedFiles.contains(change.id)) {
                                    if approvedFiles.contains(change.id) {
                                        approvedFiles.remove(change.id)
                                    } else {
                                        approvedFiles.insert(change.id)
                                    }
                                }
                            } label: {
                                HStack {
                                    Image(systemName: approvedFiles.contains(change.id) ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(approvedFiles.contains(change.id) ? .primary : .secondary)
                                    VStack(alignment: .leading) {
                                        Text(URL(fileURLWithPath: change.filePath).lastPathComponent).font(.subheadline.bold())
                                        if isRisky(change) {
                                            Label("Risky Operation", systemImage: "exclamationmark.triangle.fill").font(.caption2).foregroundStyle(.secondary)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            VStack(spacing: 12) {
                Button {
                    showingCommitSheet = true
                } label: {
                    Text("Finalize Review")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(approvedFiles.count == gitEngine.stagedChanges.count && !gitEngine.stagedChanges.isEmpty ? .primary : Color(.systemGray))
                        .cornerRadius(12)
                }
                .disabled(approvedFiles.count != gitEngine.stagedChanges.count || gitEngine.stagedChanges.isEmpty)
            }
            .padding()
            .background(Color(.systemGroupedBackground))
        }
        .navigationTitle("Change Reviewer")
    }

    private func isRisky(_ change: GitEngineService.StagedChange) -> Bool {
        change.changeType == .deleted || change.modifiedContent.count > change.originalContent.count + 500
    }
}

struct ReviewFileDetailView: View {
    let change: GitEngineService.StagedChange
    let isApproved: Bool
    let onToggleApproval: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                DiffView(original: change.originalContent, modified: change.modifiedContent)
                    .padding()

                Button {
                    onToggleApproval()
                } label: {
                    Label(isApproved ? "Approved" : "Approve Changes", systemImage: isApproved ? "checkmark.circle.fill" : "circle")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isApproved ? Color.accentColor : .primary)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
            }
        }
        .navigationTitle(URL(fileURLWithPath: change.filePath).lastPathComponent)
    }
}
