import SwiftUI

// MARK: - Repo Tools Panel

struct RepoToolsPanelView: View {
    let owner: String
    let repo: String
    @StateObject private var gitEngine = GitEngineService.shared
    @StateObject private var intelligence = RepoIntelligenceService.shared
    @State private var reportText = ""
    @State private var showingReport = false

    var body: some View {
        List {
            Section("Health Analysis") {
                Button {
                    // Demo scan
                    intelligence.scanContent(files: [
                        (path: "Sources/App.swift", content: "import SwiftUI\n@main struct App: App { var body: some Scene { WindowGroup { ContentView() } } }"),
                        (path: "Config.json", content: "{ \"token\": \"ghp_abc123456789\" }"),
                    ])
                } label: {
                    Label("Analyze Repo Health", systemImage: "stethoscope")
                }
                if intelligence.isScanning {
                    HStack { ProgressView(); Text("Scanning…").font(.caption) }
                }
                if !intelligence.securityIssues.isEmpty || !intelligence.codeSmells.isEmpty {
                    NavigationLink(destination: CodeIntelligenceView()) {
                        HStack {
                            Label("View Issues", systemImage: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                            Spacer()
                            Text("\(intelligence.securityIssues.count + intelligence.codeSmells.count)").font(.caption.bold()).foregroundStyle(.orange)
                        }
                    }
                }
            }

            Section("Cleanup") {
                Button {
                    gitEngine.clearStagingArea()
                } label: {
                    Label("Clear Staging Area", systemImage: "trash")
                }
                .foregroundStyle(.orange)

                NavigationLink(destination: LocalGitEngineView()) {
                    Label("Manage Local Git", systemImage: "externaldrive.connected.to.line.below")
                }
            }

            Section("Reports") {
                Button {
                    reportText = generateRepoReport()
                    showingReport = true
                } label: {
                    Label("Generate Repo Report", systemImage: "doc.text.fill")
                }
                .foregroundStyle(.blue)
            }

            Section("Quick Actions") {
                NavigationLink(destination: WorkflowBuilderView()) {
                    Label("Workflow Builder", systemImage: "play.rectangle.on.rectangle")
                }
                NavigationLink(destination: ReleaseManagerView(owner: owner, repo: repo)) {
                    Label("Release Manager", systemImage: "tag.fill")
                }
                NavigationLink(destination: SecurityToolsView(owner: owner, repo: repo)) {
                    Label("Security Scan", systemImage: "lock.shield")
                }
            }
        }
        .navigationTitle("Repo Tools")
        .sheet(isPresented: $showingReport) {
            ReportDetailView(report: reportText)
        }
    }

    private func generateRepoReport() -> String {
        var r = "# Repo Report: \(owner)/\(repo)\n"
        r += "Generated: \(Date().formatted(date: .complete, time: .shortened))\n\n"
        r += "## Local Git Engine\n"
        r += "• Staged changes: \(gitEngine.stagedChanges.count)\n"
        r += "• Local commits: \(gitEngine.localCommits.count)\n"
        r += "• Push queue: \(gitEngine.commitQueue.count)\n\n"
        r += "## Security\n"
        r += "• Issues found: \(intelligence.securityIssues.count)\n"
        r += "• Code smells: \(intelligence.codeSmells.count)\n"
        for issue in intelligence.securityIssues.prefix(5) {
            r += "  - [\(issue.severity.rawValue)] \(issue.description) (\(URL(fileURLWithPath: issue.filePath).lastPathComponent):L\(issue.line))\n"
        }
        return r
    }
}

// MARK: - Release Manager

struct ReleaseManagerView: View {
    let owner: String
    let repo: String
    @StateObject private var engine = GitEngineService.shared
    @State private var tagName = ""
    @State private var releaseName = ""
    @State private var releaseBody = ""
    @State private var isDraft = true
    @State private var isPrerelease = false
    @State private var generatedNotes = ""

    var body: some View {
        Form {
            Section("Release Info") {
                TextField("Tag (e.g. v1.0.0)", text: $tagName)
                TextField("Release Name", text: $releaseName)
            }

            Section("Release Notes") {
                TextEditor(text: $releaseBody)
                    .font(.system(.body, design: .monospaced))
                    .frame(minHeight: 120)
                Button("Auto-Generate Notes") {
                    generatedNotes = generateNotes()
                    releaseBody = generatedNotes
                }
                .foregroundStyle(.blue)
            }

            Section("Options") {
                Toggle("Draft Release", isOn: $isDraft)
                Toggle("Pre-release", isOn: $isPrerelease)
            }

            Section("Preview") {
                if !tagName.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("\(releaseName.isEmpty ? tagName : releaseName)")
                            .font(.headline)
                        HStack {
                            if isDraft { Label("Draft", systemImage: "pencil").font(.caption) }
                            if isPrerelease { Label("Pre-release", systemImage: "exclamationmark.circle").font(.caption).foregroundStyle(.orange) }
                        }
                        Text(releaseBody.isEmpty ? "No description." : String(releaseBody.prefix(200)))
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
            }

            Section {
                Button {
                    // In production this would call GitHubAPIClient to create the release.
                    // For now, stage it as a commit and notify.
                    engine.stageChange(filePath: "CHANGELOG.md", original: "", modified: releaseBody, changeType: GitEngineService.ChangeType.added)
                    WorkspaceNotificationService.shared.post(title: "Release Staged", body: "\(tagName) staged locally. Push to create on GitHub.", category: WorkspaceNotificationService.NotificationCategory.update)
                    tagName = ""; releaseName = ""; releaseBody = ""
                } label: {
                    Label("Stage Release", systemImage: "tray.and.arrow.up.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(tagName.isEmpty)
            }
        }
        .navigationTitle("Release Manager")
    }

    private func generateNotes() -> String {
        let commits = Array(engine.localCommits.filter(where: { $0.status != GitEngineService.CommitStatus.pushed }).prefix(20))
        if commits.isEmpty { return "No new commits since last release." }
        var notes = "## What's Changed\n\n"
        let features = commits.filter(where: { $0.category == GitEngineService.CommitCategory.feature })
        let bugfixes = commits.filter(where: { $0.category == GitEngineService.CommitCategory.bugfix })
        let others = commits.filter(where: { ![GitEngineService.CommitCategory.feature, GitEngineService.CommitCategory.bugfix].contains($0.category) })
        if !features.isEmpty {
            notes += "### Features\n"
            for c in features { notes += "- \(c.message)\n" }
        }
        if !bugfixes.isEmpty {
            notes += "\n### Bug Fixes\n"
            for c in bugfixes { notes += "- \(c.message)\n" }
        }
        if !others.isEmpty {
            notes += "\n### Other Changes\n"
            for c in others { notes += "- \(c.message)\n" }
        }
        return notes
    }
}

// MARK: - Security Tools View

struct SecurityToolsView: View {
    let owner: String
    let repo: String
    @StateObject private var intelligence = RepoIntelligenceService.shared
    @StateObject private var gitEngine = GitEngineService.shared
    @State private var blockedFiles: Set<String> = []

    var body: some View {
        List {
            Section("Secret Detection") {
                Button {
                    let stagingFiles = gitEngine.stagedChanges.map {
                        (path: $0.filePath, content: $0.modifiedContent)
                    }
                    if stagingFiles.isEmpty {
                        intelligence.scanContent(files: [
                            (path: "Config.swift", content: "let token = \"ghp_test12345\""),
                            (path: "App.swift", content: "// Normal code"),
                        ])
                    } else {
                        intelligence.scanContent(files: stagingFiles)
                    }
                } label: {
                    Label("Scan for Exposed Secrets", systemImage: "eye.slash.fill")
                }
                .foregroundStyle(.blue)

                if intelligence.isScanning {
                    HStack { ProgressView(); Text("Scanning staged files…").font(.caption) }
                }

                if !intelligence.securityIssues.isEmpty {
                    ForEach(intelligence.securityIssues) { issue in
                        HStack {
                            Image(systemName: "exclamationmark.shield.fill").foregroundStyle(.red)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(issue.description).font(.caption.bold())
                                Text("\(URL(fileURLWithPath: issue.filePath).lastPathComponent) · Line \(issue.line)")
                                    .font(.caption2).foregroundStyle(.secondary)
                            }
                            Spacer()
                            if !blockedFiles.contains(issue.filePath) {
                                Button("Block") {
                                    blockedFiles.insert(issue.filePath)
                                    gitEngine.stagedChanges.filter { $0.filePath == issue.filePath }.forEach {
                                        gitEngine.unstageChange(id: $0.id)
                                    }
                                }
                                .font(.caption.bold()).foregroundStyle(.red).buttonStyle(.bordered).controlSize(.mini)
                            } else {
                                Text("Blocked").font(.caption2).foregroundStyle(.orange)
                            }
                        }
                    }
                } else if !intelligence.isScanning {
                    HStack {
                        Image(systemName: "checkmark.shield.fill").foregroundStyle(.green)
                        Text("No secrets detected.").font(.caption).foregroundStyle(.secondary)
                    }
                }
            }

            Section("Pre-commit Validation") {
                let staged = gitEngine.stagedChanges
                if staged.isEmpty {
                    Text("No staged changes to validate.").foregroundStyle(.secondary).font(.caption)
                } else {
                    ForEach(staged) { change in
                        HStack {
                            Image(systemName: blockedFiles.contains(change.filePath) ? "xmark.circle.fill" : "checkmark.circle.fill")
                                .foregroundStyle(blockedFiles.contains(change.filePath) ? .red : .green)
                            Text(URL(fileURLWithPath: change.filePath).lastPathComponent).font(.caption)
                            Spacer()
                            Text(change.changeType.rawValue).font(.caption2).foregroundStyle(.secondary)
                        }
                    }
                }
            }

            if !blockedFiles.isEmpty {
                Section("Blocked Files (\(blockedFiles.count))") {
                    ForEach(Array(blockedFiles), id: \.self) { path in
                        Label(URL(fileURLWithPath: path).lastPathComponent, systemImage: "nosign")
                            .font(.caption).foregroundStyle(.red)
                    }
                    Button("Clear Block List") { blockedFiles = [] }
                        .foregroundStyle(.orange)
                }
            }
        }
        .navigationTitle("Security Tools")
    }
}

// MARK: - Branch Intelligence View

struct BranchIntelligenceView: View {
    let owner: String
    let repo: String
    @StateObject private var gitEngine = GitEngineService.shared
    @State private var conflictPreviewText = ""

    var body: some View {
        List {
            Section {
                Text("Connected to \(owner)/\(repo)")
                    .font(.caption).foregroundStyle(.secondary)
            } header: {
                Text("Branch Overview")
            }

            Section<AnyView, Text, EmptyView>(content: {
                AnyView(VStack(alignment: .leading) {
                    Text("Select two local commits to simulate a merge conflict preview.")
                        .font(.caption).foregroundStyle(.secondary)

                    if gitEngine.localCommits.count >= 2 {
                        let a = gitEngine.localCommits[0]
                        let b = gitEngine.localCommits[1]
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Branch A: \(a.branch)").font(.caption.bold())
                            Text("Head: \(a.message)").font(.caption).foregroundStyle(.secondary)
                            Text("Branch B: \(b.branch)").font(.caption.bold())
                            Text("Head: \(b.message)").font(.caption).foregroundStyle(.secondary)
                            Button("Preview Merge") {
                                conflictPreviewText = simulateMerge(a: a, b: b)
                            }
                            .foregroundStyle(.blue)
                        }
                        if !conflictPreviewText.isEmpty {
                            Text(conflictPreviewText)
                                .font(.system(.caption, design: .monospaced))
                                .padding(8)
                                .background(Color(uiColor: .secondarySystemBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    } else {
                        Text("Need at least 2 local commits to simulate.").font(.caption).foregroundStyle(.secondary)
                    }
                })
            }, header: {
                Text("Merge Simulation")
            })

            Section {
                let grouped = Dictionary(grouping: gitEngine.localCommits, by: { $0.branch })
                ForEach(Array(grouped.keys.sorted()), id: \.self) { branch in
                    HStack {
                        Image(systemName: "arrow.branch").foregroundStyle(.blue)
                        Text(branch).font(.subheadline)
                        Spacer()
                        Text("\(grouped[branch]?.count ?? 0) commits").font(.caption2).foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text("Divergence Visualization")
            }
        }
        .navigationTitle("Branch Intelligence")
    }

    private func simulateMerge(a: GitEngineService.LocalCommit, b: GitEngineService.LocalCommit) -> String {
        if a.branch == b.branch {
            return "⚠ Both commits are on '\(a.branch)'. No divergence detected."
        }
        return """
        Merge Preview:
        ← \(a.branch): \(a.message)
        → \(b.branch): \(b.message)
        
        Files affected: \(a.stagedFileIDs.count + b.stagedFileIDs.count)
        Conflicts: \(a.stagedFileIDs.filter { b.stagedFileIDs.contains($0) }.count)
        Status: \(a.stagedFileIDs.filter { b.stagedFileIDs.contains($0) }.isEmpty ? "✅ Clean merge expected" : "⚠ Potential conflicts")
        """
    }
}

// MARK: - Logs Intelligence View

struct LogsIntelligenceView: View {
    @State private var rawLog = ""
    @State private var parsedLines: [ParsedLogLine] = []

    struct ParsedLogLine: Identifiable {
        let id = UUID()
        let text: String
        let level: LogLevel
        let lineNumber: Int
    }

    enum LogLevel: String {
        case error = "ERROR"
        case warning = "WARNING"
        case info = "INFO"
        case debug = "DEBUG"
        case unknown = ""
    }

    var body: some View {
        VStack(spacing: 0) {
            TextEditor(text: $rawLog)
                .font(.system(.caption, design: .monospaced))
                .frame(height: 120)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.3)))
                .padding()

            Button("Parse Logs") {
                parsedLines = parseLogs(rawLog)
            }
            .buttonStyle(.borderedProminent)
            .disabled(rawLog.isEmpty)
            .padding(.bottom)

            Divider()

            List {
                ForEach(parsedLines) { line in
                    HStack(alignment: .top, spacing: 8) {
                        Text("\(line.lineNumber)").font(.caption2).foregroundStyle(.tertiary).frame(width: 28, alignment: .trailing)
                        Circle().fill(colorFor(line.level)).frame(width: 8, height: 8).padding(.top, 4)
                        Text(line.text).font(.system(.caption, design: .monospaced)).foregroundStyle(foregroundFor(line.level))
                    }
                }
            }
        }
        .navigationTitle("Logs Intelligence")
    }

    private func parseLogs(_ raw: String) -> [ParsedLogLine] {
        raw.components(separatedBy: "\n").enumerated().map { index, text in
            let level: LogLevel
            if text.localizedCaseInsensitiveContains("error") { level = .error }
            else if text.localizedCaseInsensitiveContains("warn") { level = .warning }
            else if text.localizedCaseInsensitiveContains("info") { level = .info }
            else if text.localizedCaseInsensitiveContains("debug") { level = .debug }
            else { level = .unknown }
            return ParsedLogLine(text: text, level: level, lineNumber: index + 1)
        }.filter { !$0.text.isEmpty }
    }

    private func colorFor(_ level: LogLevel) -> Color {
        switch level { case .error: return .red; case .warning: return .orange; case .info: return .blue; case .debug: return .gray; case .unknown: return .secondary }
    }

    private func foregroundFor(_ level: LogLevel) -> Color {
        switch level { case .error: return .red; case .warning: return .orange; default: return .primary }
    }
}
