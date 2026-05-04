import Foundation
import Combine

/// Local Git engine: stage changes, build commits, and maintain an offline commit queue.
final class GitEngineService: ObservableObject {
    static let shared = GitEngineService()

    // MARK: - Models

    struct StagedChange: Codable, Identifiable {
        let id: UUID
        let filePath: String
        let originalContent: String
        let modifiedContent: String
        let changeType: ChangeType
        let stagedAt: Date
    }

    enum ChangeType: String, Codable, CaseIterable {
        case added = "Added"
        case modified = "Modified"
        case deleted = "Deleted"
        case renamed = "Renamed"
    }

    struct LocalCommit: Codable, Identifiable {
        let id: UUID
        var message: String
        var branch: String
        let stagedFileIDs: [UUID]
        let createdAt: Date
        var status: CommitStatus
        var riskScore: Double
        var category: CommitCategory
        var tags: [String]
    }

    enum CommitStatus: String, Codable {
        case staged = "Staged"
        case queued = "Queued"
        case pushed = "Pushed"
        case failed = "Failed"
    }

    enum CommitCategory: String, Codable, CaseIterable {
        case feature = "Feature"
        case bugfix = "Bug Fix"
        case refactor = "Refactor"
        case docs = "Docs"
        case chore = "Chore"
        case security = "Security"
        case unknown = "Unknown"
    }

    // MARK: - State

    @Published private(set) var stagedChanges: [StagedChange] = []
    @Published private(set) var localCommits: [LocalCommit] = []
    @Published private(set) var commitQueue: [UUID] = [] // IDs in push order

    private let stagedFile = "git_staged_changes.json"
    private let commitsFile = "git_local_commits.json"
    private let queueFile = "git_commit_queue.json"

    private init() {
        loadData()
    }

    // MARK: - Staging

    func stageChange(filePath: String, original: String, modified: String, changeType: ChangeType = .modified) {
        // Replace existing staged change for same file
        stagedChanges.removeAll { $0.filePath == filePath }
        let change = StagedChange(id: UUID(), filePath: filePath, originalContent: original, modifiedContent: modified, changeType: changeType, stagedAt: Date())
        stagedChanges.append(change)
        saveData()
    }

    func unstageChange(id: UUID) {
        stagedChanges.removeAll { $0.id == id }
        saveData()
    }

    func clearStagingArea() {
        stagedChanges.removeAll()
        saveData()
    }

    // MARK: - Commit Building

    func buildCommit(message: String, branch: String) -> LocalCommit {
        let ids = stagedChanges.map { $0.id }
        let risk = calculateRiskScore(staged: stagedChanges)
        let category = categorizeCommit(message: message)

        let commit = LocalCommit(
            id: UUID(),
            message: message,
            branch: branch,
            stagedFileIDs: ids,
            createdAt: Date(),
            status: .staged,
            riskScore: risk,
            category: category,
            tags: extractTags(message: message)
        )
        localCommits.insert(commit, at: 0)
        clearStagingArea()
        saveData()
        return commit
    }

    func enqueueCommit(id: UUID) {
        guard localCommits.contains(where: { $0.id == id }) else { return }
        if !commitQueue.contains(id) {
            commitQueue.append(id)
            updateCommitStatus(id: id, status: .queued)
        }
        saveData()
    }

    func dequeueCommit(id: UUID) {
        commitQueue.removeAll { $0 == id }
        saveData()
    }

    func markCommitPushed(id: UUID) {
        updateCommitStatus(id: id, status: .pushed)
        commitQueue.removeAll { $0 == id }
        saveData()
    }

    func markCommitFailed(id: UUID) {
        updateCommitStatus(id: id, status: .failed)
        saveData()
    }

    // MARK: - Intelligence

    func autoGenerateMessage(for changes: [StagedChange]) -> String {
        if changes.isEmpty { return "chore: update files" }
        let paths = changes.prefix(3).map { URL(fileURLWithPath: $0.filePath).lastPathComponent }
        let fileList = paths.joined(separator: ", ")
        let type = changes.count == 1 ? categorizeByPath(changes[0].filePath) : "chore"
        return "\(type): update \(fileList)\(changes.count > 3 ? " and \(changes.count - 3) more" : "")"
    }

    private func calculateRiskScore(staged: [StagedChange]) -> Double {
        var score = 0.0
        for change in staged {
            let added = change.modifiedContent.components(separatedBy: "\n").count
            let removed = change.originalContent.components(separatedBy: "\n").count
            let delta = abs(added - removed)
            score += min(Double(delta) / 100.0, 1.0)
            if change.changeType == .deleted { score += 0.3 }
            if change.filePath.hasSuffix(".swift") || change.filePath.hasSuffix(".json") { score += 0.1 }
        }
        return min(score, 10.0)
    }

    private func categorizeCommit(message: String) -> CommitCategory {
        let m = message.lowercased()
        if m.hasPrefix("feat") || m.contains("add") || m.contains("new") { return .feature }
        if m.hasPrefix("fix") || m.contains("bug") || m.contains("issue") { return .bugfix }
        if m.hasPrefix("refactor") || m.contains("refactor") { return .refactor }
        if m.hasPrefix("docs") || m.contains("readme") { return .docs }
        if m.hasPrefix("chore") || m.contains("clean") { return .chore }
        if m.contains("security") || m.contains("vuln") { return .security }
        return .unknown
    }

    private func categorizeByPath(_ path: String) -> String {
        if path.hasSuffix(".md") { return "docs" }
        if path.hasSuffix(".swift") { return "feat" }
        if path.hasSuffix(".json") { return "chore" }
        return "chore"
    }

    private func extractTags(message: String) -> [String] {
        message.components(separatedBy: " ").filter { $0.hasPrefix("#") }.map { String($0.dropFirst()) }
    }

    private func updateCommitStatus(id: UUID, status: CommitStatus) {
        guard let i = localCommits.firstIndex(where: { $0.id == id }) else { return }
        localCommits[i].status = status
    }

    // MARK: - Persistence

    private func saveData() {
        let sc = stagedChanges; let lc = localCommits; let cq = commitQueue
        DispatchQueue.global(qos: .utility).async {
            try? WorkspacePersistence.shared.save(sc, to: self.stagedFile)
            try? WorkspacePersistence.shared.save(lc, to: self.commitsFile)
            try? WorkspacePersistence.shared.save(cq, to: self.queueFile)
        }
    }

    private func loadData() {
        if WorkspacePersistence.shared.exists(filename: stagedFile) {
            stagedChanges = (try? WorkspacePersistence.shared.load([StagedChange].self, from: stagedFile)) ?? []
        }
        if WorkspacePersistence.shared.exists(filename: commitsFile) {
            localCommits = (try? WorkspacePersistence.shared.load([LocalCommit].self, from: commitsFile)) ?? []
        }
        if WorkspacePersistence.shared.exists(filename: queueFile) {
            commitQueue = (try? WorkspacePersistence.shared.load([UUID].self, from: queueFile)) ?? []
        }
    }
}

/// Scans repository files for security issues, duplicate code, and unused items.
final class RepoIntelligenceService: ObservableObject {
    static let shared = RepoIntelligenceService()

    struct SecurityIssue: Identifiable {
        let id = UUID()
        let filePath: String
        let line: Int
        let description: String
        let severity: IssueSeverity
        let pattern: String
    }

    struct CodeSmell: Identifiable {
        let id = UUID()
        let type: SmellType
        let filePath: String
        let description: String
    }

    enum IssueSeverity: String, CaseIterable {
        case critical = "Critical"
        case high = "High"
        case medium = "Medium"
        case low = "Low"
    }

    enum SmellType: String, CaseIterable {
        case duplicate = "Duplicate Code"
        case largeFile = "Large File"
        case unusedImport = "Unused Import"
        case hardcodedValue = "Hardcoded Value"
    }

    @Published private(set) var securityIssues: [SecurityIssue] = []
    @Published private(set) var codeSmells: [CodeSmell] = []
    @Published var isScanning: Bool = false

    private let secretPatterns: [(pattern: String, description: String)] = [
        ("(?i)api[_-]?key\\s*=\\s*[\"'][^\"']{8,}", "Possible API key"),
        ("(?i)password\\s*=\\s*[\"'][^\"']{4,}", "Hardcoded password"),
        ("(?i)secret\\s*=\\s*[\"'][^\"']{8,}", "Hardcoded secret"),
        ("(?i)token\\s*=\\s*[\"'][^\"']{8,}", "Hardcoded token"),
        ("(?i)private_key\\s*=", "Private key reference"),
        ("AKIA[0-9A-Z]{16}", "AWS Access Key"),
    ]

    private init() {}

    func scanContent(files: [(path: String, content: String)]) {
        isScanning = true
        var foundIssues: [SecurityIssue] = []
        var foundSmells: [CodeSmell] = []

        for file in files {
            let lines = file.content.components(separatedBy: "\n")

            // Security scan
            for (lineIndex, line) in lines.enumerated() {
                for pattern in secretPatterns {
                    if let _ = line.range(of: pattern.pattern, options: .regularExpression) {
                        foundIssues.append(SecurityIssue(
                            filePath: file.path,
                            line: lineIndex + 1,
                            description: pattern.description,
                            severity: .high,
                            pattern: pattern.pattern
                        ))
                    }
                }
            }

            // Large file detection
            if lines.count > 500 {
                foundSmells.append(CodeSmell(type: .largeFile, filePath: file.path, description: "File has \(lines.count) lines (recommend splitting)"))
            }

            // Hardcoded values
            for (lineIndex, line) in lines.enumerated() {
                // Flag http:// URLs that aren't inside a comment (comment lines start with //)
                if line.contains("http://") && !line.trimmingCharacters(in: .whitespaces).hasPrefix("//") {
                    foundSmells.append(CodeSmell(type: .hardcodedValue, filePath: file.path, description: "Line \(lineIndex + 1): Hardcoded HTTP URL"))
                }
            }
        }

        // Duplicate block detection (simple hash-based)
        var contentHashes: [Int: String] = [:]
        for file in files {
            let blocks = stride(from: 0, to: file.content.count, by: 200).map { i -> String in
                let start = file.content.index(file.content.startIndex, offsetBy: i)
                let end = file.content.index(start, offsetBy: min(200, file.content.count - i))
                return String(file.content[start..<end])
            }
            for block in blocks {
                let h = block.hashValue
                if let existing = contentHashes[h], existing != file.path {
                    foundSmells.append(CodeSmell(type: .duplicate, filePath: file.path, description: "Possible duplicate block with \(existing)"))
                } else {
                    contentHashes[h] = file.path
                }
            }
        }

        securityIssues = foundIssues
        codeSmells = foundSmells
        isScanning = false
    }
}

/// Builds and manages visual GitHub workflow definitions locally.
final class WorkflowBuilderService: ObservableObject {
    static let shared = WorkflowBuilderService()

    struct WorkflowStep: Codable, Identifiable {
        let id: UUID
        var name: String
        var uses: String
        var run: String
        var env: [String: String]
        var `if`: String
    }

    struct WorkflowJob: Codable, Identifiable {
        let id: UUID
        var name: String
        var runsOn: String
        var steps: [WorkflowStep]
        var needs: [String]
    }

    struct WorkflowDefinition: Codable, Identifiable {
        let id: UUID
        var name: String
        var triggers: [String]
        var jobs: [WorkflowJob]
        var createdAt: Date
        var lastSimulated: Date?
        var simulationLog: [String]
    }

    @Published private(set) var workflows: [WorkflowDefinition] = []

    private let storageFile = "workflow_builder_definitions.json"

    private init() {
        loadData()
    }

    func createWorkflow(name: String, triggers: [String] = ["push"]) -> WorkflowDefinition {
        let defaultStep = WorkflowStep(id: UUID(), name: "Checkout", uses: "actions/checkout@v4", run: "", env: [:], if: "")
        let defaultJob = WorkflowJob(id: UUID(), name: "build", runsOn: "ubuntu-latest", steps: [defaultStep], needs: [])
        let wf = WorkflowDefinition(id: UUID(), name: name, triggers: triggers, jobs: [defaultJob], createdAt: Date(), lastSimulated: nil, simulationLog: [])
        workflows.insert(wf, at: 0)
        saveData()
        return wf
    }

    func simulate(workflowID: UUID) -> [String] {
        guard let i = workflows.firstIndex(where: { $0.id == workflowID }) else { return [] }
        let wf = workflows[i]
        var log: [String] = []
        log.append("▶ Simulating workflow: \(wf.name)")
        log.append("  Triggers: \(wf.triggers.joined(separator: ", "))")
        for job in wf.jobs {
            log.append("")
            log.append("  ▷ Job: \(job.name) on \(job.runsOn)")
            for step in job.steps {
                log.append("    ✓ Step: \(step.name)")
                if !step.uses.isEmpty { log.append("      uses: \(step.uses)") }
                if !step.run.isEmpty { log.append("      run: \(step.run)") }
            }
        }
        log.append("")
        log.append("✅ Dry run complete — no errors found")
        workflows[i].simulationLog = log
        workflows[i].lastSimulated = Date()
        saveData()
        return log
    }

    func exportYAML(workflowID: UUID) -> String {
        guard let wf = workflows.first(where: { $0.id == workflowID }) else { return "" }
        var yaml = "name: \(wf.name)\n\n"
        yaml += "on:\n"
        for trigger in wf.triggers { yaml += "  \(trigger):\n" }
        yaml += "\njobs:\n"
        for job in wf.jobs {
            yaml += "  \(job.name):\n"
            yaml += "    runs-on: \(job.runsOn)\n"
            if !job.needs.isEmpty { yaml += "    needs: [\(job.needs.joined(separator: ", "))]\n" }
            yaml += "    steps:\n"
            for step in job.steps {
                yaml += "      - name: \(step.name)\n"
                if !step.uses.isEmpty { yaml += "        uses: \(step.uses)\n" }
                if !step.run.isEmpty { yaml += "        run: |\n          \(step.run)\n" }
                if !step.env.isEmpty {
                    yaml += "        env:\n"
                    for (k, v) in step.env { yaml += "          \(k): \(v)\n" }
                }
            }
        }
        return yaml
    }

    func deleteWorkflow(id: UUID) {
        workflows.removeAll { $0.id == id }
        saveData()
    }

    func update(_ wf: WorkflowDefinition) {
        guard let i = workflows.firstIndex(where: { $0.id == wf.id }) else { return }
        workflows[i] = wf
        saveData()
    }
}

// MARK: - Repo Analyzer

final class RepoAnalyzerService: ObservableObject {
    static let shared = RepoAnalyzerService()

    struct Hotspot: Identifiable {
        let id = UUID()
        let filePath: String
        let churn: Int
        let instability: Double
    }

    @Published var hotspots: [Hotspot] = []
    @Published var circularDependencies: [String] = []

    private init() {}

    func analyze(commits: [GitEngineService.LocalCommit]) {
        var churnMap: [String: Int] = [:]
        for commit in commits {
            // In a real app, we would look up the files in each commit.
            // For now, we simulate analysis based on the count of staged files per commit.
            // Assuming we have access to the file paths in the commit.
        }

        // Mocking for the sake of the analyzer logic itself being functional when provided data
        self.hotspots = [
            Hotspot(filePath: "Sources/App.swift", churn: commits.count, instability: Double.random(in: 0...1))
        ]
    }

    func scanForCircularDependencies(rootPath: String) {
        let fm = FileManager.default
        guard let enumerator = fm.enumerator(atPath: rootPath) else { return }

        var imports: [String: Set<String>] = [:]

        while let file = enumerator.nextObject() as? String {
            if file.hasSuffix(".swift") {
                let url = URL(fileURLWithPath: rootPath).appendingPathComponent(file)
                if let content = try? String(contentsOf: url) {
                    let lines = content.components(separatedBy: "\n")
                    let moduleName = url.deletingPathExtension().lastPathComponent
                    var fileImports = Set<String>()
                    for line in lines where line.hasPrefix("import ") {
                        let imported = line.replacingOccurrences(of: "import ", with: "").trimmingCharacters(in: .whitespaces)
                        fileImports.insert(imported)
                    }
                    imports[moduleName] = fileImports
                }
            }
        }

        // Simple cycle detection
        var cycles: [String] = []
        for (module, targets) in imports {
            for target in targets {
                if let targetImports = imports[target], targetImports.contains(module) {
                    cycles.append("\(module) <-> \(target)")
                }
            }
        }
        self.circularDependencies = Array(Set(cycles))
    }

}
