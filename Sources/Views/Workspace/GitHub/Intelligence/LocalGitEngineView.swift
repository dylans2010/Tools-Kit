import SwiftUI

// MARK: - Local Git Engine View

struct LocalGitEngineView: View {
    @StateObject private var gitEngine = GitEngineService.shared
    @State private var showingCommitBuilder = false
    @State private var showingStageFile = false
    @State private var newMessage = ""
    @State private var newBranch = "main"

    var body: some View {
        List {
            // Staging area
            Section {
                if gitEngine.stagedChanges.isEmpty {
                    Text("No staged changes. Stage files to build a commit.")
                        .foregroundStyle(.secondary).font(.caption)
                } else {
                    ForEach(gitEngine.stagedChanges) { change in
                        StagedChangeRow(change: change)
                    }
                    Button("Clear Staging Area", role: .destructive) {
                        gitEngine.clearStagingArea()
                    }
                }

                Button(action: { showingStageFile = true }) {
                    Label("Stage a Change", systemImage: "plus.circle")
                }
                .foregroundStyle(.blue)
            } header: {
                HStack {
                    Text("Staging Area")
                    Spacer()
                    Text("\(gitEngine.stagedChanges.count) file(s)").font(.caption).foregroundStyle(.secondary)
                }
            }

            // Commit builder
            if !gitEngine.stagedChanges.isEmpty {
                Section {
                    TextField("Commit message…", text: $newMessage)
                    TextField("Branch", text: $newBranch)
                    Button("Auto-Generate Message") {
                        newMessage = gitEngine.autoGenerateMessage(for: gitEngine.stagedChanges)
                    }
                    .foregroundStyle(.blue)
                    Button("Build & Stage Commit") {
                        guard !newMessage.isEmpty else { return }
                        let _ = gitEngine.buildCommit(message: newMessage, branch: newBranch)
                        newMessage = ""
                    }
                    .disabled(newMessage.isEmpty)
                    .foregroundStyle(.green)
                } header: {
                    Text("Build Commit")
                }
            }

            // Local commit history
            Section {
                if gitEngine.localCommits.isEmpty {
                    Text("No local commits yet.").foregroundStyle(.secondary).font(.caption)
                } else {
                    ForEach(gitEngine.localCommits) { commit in
                        LocalCommitRow(commit: commit)
                    }
                }
            } header: {
                Text("Local Commits (\(gitEngine.localCommits.count))")
            }

            // Push queue
            if !gitEngine.commitQueue.isEmpty {
                Section {
                    ForEach(gitEngine.commitQueue, id: \.self) { id in
                        if let commit = gitEngine.localCommits.first(where: { $0.id == id }) {
                            HStack {
                                Text(commit.message).font(.caption)
                                Spacer()
                                Button("Dequeue") { gitEngine.dequeueCommit(id: id) }
                                    .font(.caption).foregroundStyle(.orange)
                            }
                        }
                    }
                } header: {
                    Text("Push Queue (\(gitEngine.commitQueue.count))")
                }
            }
        }
        .navigationTitle("Local Git Engine")
        .sheet(isPresented: $showingStageFile) {
            StageFileView()
        }
    }
}

struct StagedChangeRow: View {
    let change: GitEngineService.StagedChange
    @StateObject private var engine = GitEngineService.shared

    var body: some View {
        HStack {
            Image(systemName: iconFor(change.changeType))
                .foregroundStyle(colorFor(change.changeType))
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 2) {
                Text(URL(fileURLWithPath: change.filePath).lastPathComponent).font(.subheadline)
                Text(change.filePath).font(.caption2).foregroundStyle(.secondary).lineLimit(1)
            }
            Spacer()
            Text(change.changeType.rawValue).font(.caption2).foregroundStyle(.secondary)
            Button(action: { engine.unstageChange(id: change.id) }) {
                Image(systemName: "minus.circle").foregroundStyle(.red)
            }
        }
    }

    private func iconFor(_ type: GitEngineService.ChangeType) -> String {
        switch type {
        case .added: return "plus.circle.fill"
        case .modified: return "pencil.circle.fill"
        case .deleted: return "minus.circle.fill"
        case .renamed: return "arrow.triangle.2.circlepath.circle.fill"
        }
    }

    private func colorFor(_ type: GitEngineService.ChangeType) -> Color {
        switch type { case .added: return .green; case .modified: return .orange; case .deleted: return .red; case .renamed: return .blue }
    }
}

struct LocalCommitRow: View {
    let commit: GitEngineService.LocalCommit
    @StateObject private var engine = GitEngineService.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: badgeIcon(commit.status))
                    .foregroundStyle(badgeColor(commit.status))
                    .font(.caption)
                Text(commit.message).font(.subheadline).bold().lineLimit(1)
                Spacer()
                Text(commit.category.rawValue).font(.caption2)
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(Color.blue.opacity(0.12))
                    .clipShape(Capsule())
            }
            HStack {
                Text("Branch: \(commit.branch)").font(.caption2).foregroundStyle(.secondary)
                Text("·").foregroundStyle(.secondary).font(.caption2)
                Text("Risk: \(String(format: "%.1f", commit.riskScore))").font(.caption2).foregroundStyle(commit.riskScore > 5 ? .red : .secondary)
                Text("·").foregroundStyle(.secondary).font(.caption2)
                Text(commit.createdAt.formatted(date: .abbreviated, time: .shortened)).font(.caption2).foregroundStyle(.secondary)
            }
            if commit.status == .staged {
                Button("Add to Push Queue") { engine.enqueueCommit(id: commit.id) }
                    .font(.caption.bold()).foregroundStyle(.blue)
            }
        }
        .padding(.vertical, 2)
    }

    private func badgeIcon(_ status: GitEngineService.CommitStatus) -> String {
        switch status { case .staged: return "clock.fill"; case .queued: return "tray.fill"; case .pushed: return "checkmark.circle.fill"; case .failed: return "xmark.circle.fill" }
    }
    private func badgeColor(_ status: GitEngineService.CommitStatus) -> Color {
        switch status { case .staged: return .orange; case .queued: return .blue; case .pushed: return .green; case .failed: return .red }
    }
}

struct StageFileView: View {
    @StateObject private var engine = GitEngineService.shared
    @Environment(\.dismiss) var dismiss
    @State private var filePath = ""
    @State private var originalContent = ""
    @State private var modifiedContent = ""
    @State private var changeType = GitEngineService.ChangeType.modified

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("e.g. Sources/Models/User.swift", text: $filePath)
                } header: {
                    Text("File Path")
                }
                Section {
                    Picker("Type", selection: $changeType) {
                        ForEach(GitEngineService.ChangeType.allCases, id: \.self) { t in
                            Text(t.rawValue).tag(t)
                        }
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text("Change Type")
                }
                Section {
                    TextEditor(text: $originalContent)
                        .font(.system(.caption, design: .monospaced))
                        .frame(minHeight: 80)
                } header: {
                    Text("Original Content (optional)")
                }
                Section {
                    TextEditor(text: $modifiedContent)
                        .font(.system(.caption, design: .monospaced))
                        .frame(minHeight: 80)
                } header: {
                    Text("Modified Content")
                }
            }
            .navigationTitle("Stage Change")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Stage") {
                        engine.stageChange(filePath: filePath, original: originalContent, modified: modifiedContent, changeType: changeType)
                        dismiss()
                    }
                    .disabled(filePath.isEmpty)
                }
            }
        }
    }
}
