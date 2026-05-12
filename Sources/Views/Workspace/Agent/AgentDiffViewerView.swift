import SwiftUI

struct AgentDiffViewerView: View {
    @ObservedObject var state: AgentSessionState
    @State private var selectedFile: String?
    @State private var isApplying = false
    @State private var applyError: String?

    var body: some View {
        HStack(spacing: 0) {
            // File List
            List(selection: $selectedFile) {
                if state.diffs.isEmpty {
                    Text("No code changes.")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(Array(state.diffs.keys).sorted(), id: \.self) { path in
                        Text((path as NSString).lastPathComponent)
                            .tag(path)
                    }
                }
            }
            .frame(width: 200)
            .listStyle(.sidebar)

            Divider()

            // Diff Viewer
            if let path = selectedFile, let diff = state.diffs[path] {
                VStack(spacing: 0) {
                    SideBySideDiffView(path: path, diff: diff.diff)

                    Divider()

                    HStack(spacing: 16) {
                        Button(action: { acceptChanges(for: path, diff: diff.diff) }) {
                            if isApplying {
                                ProgressView().tint(.white)
                            } else {
                                Label("Accept Changes", systemImage: "checkmark.circle.fill")
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.green)
                        .disabled(isApplying)

                        Button(action: { selectedFile = nil }) {
                            Label("Reject Changes", systemImage: "xmark.circle.fill")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                        }
                        .buttonStyle(.bordered)
                        .tint(.red)
                        .disabled(isApplying)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                }
            } else {
                ContentUnavailableView(
                    "Select a File",
                    systemImage: "doc.text.magnifyingglass",
                    description: Text("Select a file from the sidebar to view its changes.")
                )
            }
        }
        .navigationTitle("Diff Viewer")
        .onAppear {
            if selectedFile == nil {
                selectedFile = state.diffs.keys.sorted().first
            }
        }
        .alert("Action Failed", isPresented: Binding(get: { applyError != nil }, set: { if !$0 { applyError = nil } })) {
            Button("OK") { applyError = nil }
        } message: {
            if let error = applyError {
                Text(error)
            }
        }
    }

    private func acceptChanges(for path: String, diff: String) {
        isApplying = true
        Task {
            do {
                let context = SystemToolContext(workspaceId: state.workspaceId, sessionId: state.id, timestamp: ISO8601DateFormatter().string(from: Date()))
                _ = try await AgentSystemTools.shared.execute(name: "apply_patch", input: ["path": path, "patch": diff], context: context)

                await MainActor.run {
                    isApplying = false
                    // Optionally remove the diff from the list after applying
                }
            } catch {
                await MainActor.run {
                    isApplying = false
                    applyError = error.localizedDescription
                }
            }
        }
    }
}

struct SideBySideDiffView: View {
    let path: String
    let diff: String

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(path)
                .font(.caption.bold())
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.secondarySystemBackground))

            HStack(spacing: 0) {
                // Left side: Old (Deletions)
                ScrollView([.horizontal, .vertical]) {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(parseDiff(diff).filter { $0.type != .addition }, id: \.id) { line in
                            DiffLineRow(line: line)
                        }
                    }
                    .padding(.vertical)
                }

                Divider()

                // Right side: New (Additions)
                ScrollView([.horizontal, .vertical]) {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(parseDiff(diff).filter { $0.type != .deletion }, id: \.id) { line in
                            DiffLineRow(line: line)
                        }
                    }
                    .padding(.vertical)
                }
            }
        }
    }

    private func parseDiff(_ diff: String) -> [DiffLine] {
        var lines: [DiffLine] = []
        let components = diff.components(separatedBy: .newlines)
        for (index, content) in components.enumerated() {
            let type: DiffLineType
            if content.hasPrefix("+") { type = .addition }
            else if content.hasPrefix("-") { type = .deletion }
            else if content.hasPrefix("@@") { type = .header }
            else { type = .context }

            lines.append(DiffLine(id: index, content: content, type: type))
        }
        return lines
    }
}

enum DiffLineType: Sendable {
    case addition, deletion, context, header
}

struct DiffLine: Identifiable, Sendable {
    let id: Int
    let content: String
    let type: DiffLineType
}

struct DiffLineRow: View {
    let line: DiffLine

    var body: some View {
        HStack(spacing: 0) {
            Text(line.content)
                .font(.system(.caption2, design: .monospaced))
                .padding(.horizontal, 8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(backgroundColor)
        }
    }

    private var backgroundColor: Color {
        switch line.type {
        case .addition: return Color.green.opacity(0.15)
        case .deletion: return Color.red.opacity(0.15)
        case .header: return Color.blue.opacity(0.1)
        case .context: return .clear
        }
    }
}
