import SwiftUI

struct NotebookAuditLogsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var manager = NotebooksManager.shared
    let pageID: UUID

    @State private var logs: [AuditEntry] = []

    struct AuditEntry: Identifiable, Sendable {
        let id = UUID()
        let action: String
        let details: String
        let timestamp: Date
        let user: String
    }

    var body: some View {
        NavigationStack {
            List {
                if logs.isEmpty {
                    Text("No logs found for this page.")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(logs) { log in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(log.action)
                                    .font(.subheadline.bold())
                                Spacer()
                                Text(log.timestamp, style: .date)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            Text(log.details)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("By \(log.user)")
                                .font(.caption2.italic())
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Audit Logs")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
            .onAppear(perform: generateLogs)
        }
    }

    private func generateLogs() {
        // Simulate logs based on page history and other actions
        var generated: [AuditEntry] = []

        // Find the page in manager to get real data if possible
        for notebook in manager.notebooks {
            for folder in notebook.folders {
                if let page = folder.pages.first(where: { $0.id == pageID }) {
                    generated.append(AuditEntry(action: "Page Created", details: "Page titled '\(page.title)' was created.", timestamp: page.createdAt, user: "System"))

                    for version in page.history {
                        generated.append(AuditEntry(action: "Page Updated", details: "Content changes were saved.", timestamp: version.timestamp, user: version.author))
                    }

                    if page.updatedAt > page.createdAt {
                         generated.append(AuditEntry(action: "Last Modification", details: "Most recent sync and save completed.", timestamp: page.updatedAt, user: "Local User"))
                    }
                }
            }
        }

        logs = generated.sorted(by: { $0.timestamp > $1.timestamp })
    }
}
