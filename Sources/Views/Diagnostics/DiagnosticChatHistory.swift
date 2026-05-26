import SwiftUI

struct DiagnosticChatHistory: View {
    @StateObject private var store = DiagnosticChatStore.shared
    @State private var searchText = ""
    @State private var editingSession: DiagnosticChatSession?
    @State private var newTitle = ""
    @State private var showRenameAlert = false
    @Environment(\.dismiss) private var dismiss

    var onSelectSession: (DiagnosticChatSession) -> Void

    var filteredSessions: [DiagnosticChatSession] {
        if searchText.isEmpty {
            return store.sessions
        } else {
            return store.sessions.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.messages.last?.content.localizedCaseInsensitiveContains(searchText) ?? false
            }
        }
    }

    var body: some View {
        NavigationStack {
            List {
                if filteredSessions.isEmpty {
                    ContentUnavailableView(
                        "No Chat History",
                        systemImage: "bubble.left.and.bubble.right",
                        description: Text("Your diagnostic chat sessions will appear here.")
                    )
                } else {
                    ForEach(filteredSessions) { session in
                        Button {
                            onSelectSession(session)
                            dismiss()
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(session.title)
                                    .font(.headline)
                                    .foregroundStyle(.primary)

                                if let lastMessage = session.messages.last {
                                    Text(lastMessage.content)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }

                                Text(session.updatedAt, style: .relative)
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                            .padding(.vertical, 4)
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                store.deleteSession(id: session.id)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }

                            Button {
                                editingSession = session
                                newTitle = session.title
                                showRenameAlert = true
                            } label: {
                                Label("Rename", systemImage: "pencil")
                            }
                            .tint(.orange)

                            Button {
                                exportSession(session)
                            } label: {
                                Label("Export", systemImage: "square.and.arrow.up")
                            }
                            .tint(.blue)
                        }
                    }
                }
            }
            .navigationTitle("Chat History")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search history")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .alert("Rename Chat", isPresented: $showRenameAlert) {
                TextField("Title", text: $newTitle)
                Button("Cancel", role: .cancel) { editingSession = nil }
                Button("Save") {
                    if let session = editingSession {
                        store.updateTitle(id: session.id, title: newTitle)
                    }
                    editingSession = nil
                }
            } message: {
                Text("Enter a new title for this diagnostic session.")
            }
        }
    }

    private func exportSession(_ session: DiagnosticChatSession) {
        var exportText = "Diagnostic Chat: \(session.title)\n"
        exportText += "Created: \(session.createdAt.formatted())\n"
        exportText += "-----------------------------------\n\n"

        for message in session.messages {
            exportText += "[\(message.role.uppercased())] \(message.timestamp.formatted())\n"
            exportText += "\(message.content)\n\n"
        }

        let av = UIActivityViewController(activityItems: [exportText], applicationActivities: nil)
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = scene.windows.first?.rootViewController {
            rootVC.present(av, animated: true)
        }
    }
}
