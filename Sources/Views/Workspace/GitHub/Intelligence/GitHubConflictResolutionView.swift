import SwiftUI

struct GitHubConflictResolutionView: View {
    @State private var conflicts: [ConflictBlock] = [
        ConflictBlock(id: UUID(), currentContent: "let value = 10", incomingContent: "let value = 20", fileName: "Config.swift")
    ]
    @ObservedObject private var gitEngine = GitEngineService.shared

    var body: some View {
        List {
            Section {
                ForEach(conflicts) { conflict in
                    VStack(alignment: .leading, spacing: 12) {
                        Text(conflict.fileName).font(.caption.bold()).foregroundStyle(.secondary)

                        VStack(spacing: 0) {
                            ConflictSideView(title: "Current Branch", content: conflict.currentContent, color: .blue) {
                                resolveConflict(conflict, with: conflict.currentContent)
                            }

                            Divider()

                            ConflictSideView(title: "Incoming Changes", content: conflict.incomingContent, color: .green) {
                                resolveConflict(conflict, with: conflict.incomingContent)
                            }
                        }
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.secondary.opacity(0.2)))

                        NavigationLink("Manual Merge Editor") {
                            TextEditor(text: .constant(conflict.currentContent + "\n" + conflict.incomingContent))
                                .navigationTitle("Manual Merge")
                        }
                        .font(.caption.bold())
                    }
                    .padding(.vertical, 8)
                }
            } header: {
                Text("Merge Conflicts Detected")
            }
        }
        .navigationTitle("Conflict Resolution")
    }

    private func resolveConflict(_ conflict: ConflictBlock, with resolvedContent: String) {
        gitEngine.stageChange(filePath: conflict.fileName, original: conflict.currentContent, modified: resolvedContent)
        conflicts.removeAll { $0.id == conflict.id }
    }
}

struct ConflictBlock: Identifiable, Sendable {
    let id: UUID
    let currentContent: String
    let incomingContent: String
    let fileName: String
}

struct ConflictSideView: View {
    let title: String
    let content: String
    let color: Color
    let onAccept: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title).font(.caption2.bold()).foregroundStyle(color)
                Spacer()
                Button("Accept") { onAccept() }
                    .font(.caption2.bold())
                    .buttonStyle(.bordered)
                    .tint(color)
            }
            Text(content)
                .font(.system(.caption2, design: .monospaced))
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(color.opacity(0.05))
        }
        .padding(12)
    }
}
