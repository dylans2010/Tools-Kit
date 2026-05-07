import SwiftUI

struct SDKActionConsoleView: View {
    @State private var command = ""
    @StateObject private var logBus = SDKConsoleView.LogBus.shared
    @StateObject private var runtime = SDKRuntimeEngine.shared
    @State private var isExecuting = false

    var body: some View {
        VStack(spacing: 0) {
            SDKConsoleView()
                .frame(maxHeight: .infinity)

            Divider()

            if runtime.isNoSandboxModeEnabled {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.orange)
                    Text("NoSandbox Mode Active").font(.caption).bold()
                }
                .padding(.vertical, 4)
                .frame(maxWidth: .infinity)
                .background(Color.orange.opacity(0.1))
            }

            HStack(spacing: 12) {
                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
                    .font(.system(.body, design: .monospaced))

                TextField("Enter SDK Command...", text: $command)
                    .font(.system(.body, design: .monospaced))
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .onSubmit { executeCommand() }

                if isExecuting {
                    ProgressView().controlSize(.small)
                } else {
                    Button(action: executeCommand) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title2)
                    }
                    .disabled(command.isEmpty)
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
        }
        .navigationTitle("Action Console")
    }

    private func executeCommand() {
        guard !command.isEmpty else { return }
        let cmd = command
        command = ""
        isExecuting = true

        logBus.log("> \(cmd)", type: .info)

        let context = SDKExecutionContext(projectID: UUID(), noSandbox: runtime.isNoSandboxModeEnabled)

        Task {
            do {
                if cmd.starts(with: "note ") {
                    let title = cmd.replacingOccurrences(of: "note ", with: "")
                    try await SDKExecutionKernel.shared.execute(action: .createNote(title: title, content: "Created from Console"), context: context)
                    logBus.log("Note created: \(title)", type: .success)
                } else if cmd.starts(with: "task ") {
                    let title = cmd.replacingOccurrences(of: "task ", with: "")
                    try await SDKExecutionKernel.shared.execute(action: .createTask(title: title, dueDate: nil), context: context)
                    logBus.log("Task created: \(title)", type: .success)
                } else if cmd.starts(with: "deck ") {
                    let title = cmd.replacingOccurrences(of: "deck ", with: "")
                    try await SDKExecutionKernel.shared.execute(action: .createDeck(title: title), context: context)
                    logBus.log("Slide deck created: \(title)", type: .success)
                } else if cmd.starts(with: "persona ") {
                    let prompt = cmd.replacingOccurrences(of: "persona ", with: "")
                    try await SDKExecutionKernel.shared.execute(action: .queryPersona(prompt: prompt), context: context)
                    logBus.log("Persona query submitted", type: .success)
                } else if cmd.starts(with: "snapshot ") {
                    let message = cmd.replacingOccurrences(of: "snapshot ", with: "")
                    WorkspaceAPI.shared.timeTravel.createSnapshot(message: message)
                    logBus.log("Snapshot created: \(message)", type: .success)
                } else if cmd == "list notes" {
                    let notes = WorkspaceAPI.shared.notes.listNotes()
                    logBus.log("Found \(notes.count) notes:", type: .info)
                    for note in notes.prefix(10) {
                        logBus.log("  - \(note.title)", type: .info)
                    }
                } else if cmd == "list tasks" {
                    let tasks = WorkspaceAPI.shared.tasks.listTasks()
                    logBus.log("Found \(tasks.count) tasks:", type: .info)
                    for task in tasks.prefix(10) {
                        logBus.log("  - [\(task.completed ? "x" : " ")] \(task.title)", type: .info)
                    }
                } else if cmd == "list files" {
                    let files = WorkspaceAPI.shared.files.listFiles()
                    logBus.log("Found \(files.count) files:", type: .info)
                    for file in files.prefix(10) {
                        logBus.log("  - \(file.name)", type: .info)
                    }
                } else if cmd == "list decks" {
                    let decks = WorkspaceAPI.shared.slides.listDecks()
                    logBus.log("Found \(decks.count) slide decks:", type: .info)
                    for deck in decks.prefix(10) {
                        logBus.log("  - \(deck.title)", type: .info)
                    }
                } else if cmd == "list snapshots" {
                    let snapshots = WorkspaceAPI.shared.timeTravel.listSnapshots()
                    logBus.log("Found \(snapshots.count) snapshots:", type: .info)
                    for snap in snapshots.prefix(10) {
                        logBus.log("  - \(snap.message) (\(snap.timestamp.formatted()))", type: .info)
                    }
                } else if cmd == "status" {
                    logBus.log("SDK Status:", type: .info)
                    logBus.log("  Mode: \(runtime.isNoSandboxModeEnabled ? "NoSandbox" : "Sandboxed")", type: .info)
                    logBus.log("  Active Projects: \(runtime.activeProjects.count)", type: .info)
                    logBus.log("  Connectors: \(SDKConnectorManager.shared.connectors.count)", type: .info)
                    logBus.log("  Plugins: \(SDKPluginManager.shared.plugins.count)", type: .info)
                    let metrics = SDKTelemetryEngine.shared.getMetrics()
                    logBus.log("  Traces: \(metrics.totalTraces) (avg \(String(format: "%.0f", metrics.averageDurationMs))ms)", type: .info)
                } else if cmd == "clear" {
                    logBus.clear()
                } else if cmd == "help" {
                    logBus.log("Available commands:", type: .info)
                    logBus.log("  note [title]       - Create a note", type: .info)
                    logBus.log("  task [title]       - Create a task", type: .info)
                    logBus.log("  deck [title]       - Create a slide deck", type: .info)
                    logBus.log("  persona [prompt]   - Query AI persona", type: .info)
                    logBus.log("  snapshot [message] - Create workspace snapshot", type: .info)
                    logBus.log("  list notes/tasks/files/decks/snapshots", type: .info)
                    logBus.log("  status             - Show SDK status", type: .info)
                    logBus.log("  clear              - Clear console", type: .info)
                    logBus.log("  help               - Show this help", type: .info)
                } else {
                    logBus.log("Unknown command: \(cmd). Type 'help' for available commands.", type: .error)
                }
            } catch {
                logBus.log("Execution failed: \(error.localizedDescription)", type: .error)
            }

            await MainActor.run { isExecuting = false }
        }
    }
}
