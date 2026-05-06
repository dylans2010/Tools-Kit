import SwiftUI

struct SDKActionConsoleView: View {
    @State private var command = ""
    @StateObject private var logBus = SDKConsoleView.LogBus.shared
    @State private var isExecuting = false

    var body: some View {
        VStack(spacing: 0) {
            // Log Area
            SDKConsoleView()
                .frame(maxHeight: .infinity)

            Divider()

            // Command Input
            HStack(spacing: 12) {
                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
                    .font(.system(.body, design: .monospaced))

                TextField("Enter SDK command...", text: $command)
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

        let context = SDKExecutionContext(projectID: UUID(), noSandbox: SDKRuntimeEngine.shared.isNoSandboxModeEnabled)

        Task {
            // Simple command parser bridging to SDK Kernel
            do {
                if cmd.starts(with: "note ") {
                    let title = cmd.replacingOccurrences(of: "note ", with: "")
                    try await SDKExecutionKernel.shared.execute(action: .createNote(title: title, content: "Created from Console"), context: context)
                } else if cmd == "list notes" {
                    let notes = WorkspaceAPI.shared.notes.listNotes()
                    logBus.log("Found \(notes.count) notes.", type: .info)
                } else if cmd == "help" {
                    logBus.log("Available commands: note [title], list notes, clear, help", type: .info)
                } else if cmd == "clear" {
                    logBus.clear()
                } else {
                    logBus.log("Unknown command: \(cmd)", type: .error)
                }
            } catch {
                logBus.log("Execution failed: \(error.localizedDescription)", type: .error)
            }

            await MainActor.run { isExecuting = false }
        }
    }
}
