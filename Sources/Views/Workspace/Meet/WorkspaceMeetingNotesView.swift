import SwiftUI

struct WorkspaceMeetingNotesView: View {
    @ObservedObject var manager: MeetingStateManager
    @StateObject private var notesManager = MeetingNotesManager.shared

    @State private var notes = ""
    @State private var aiResult = ""
    @State private var isLoading = false

    var body: some View {
        List {
            NotesEditorView(notes: $notes) {
                saveNotes()
            }
            .listRowSeparator(.hidden)

            AIAssistantPanelView(
                notes: notes,
                onSummarize: { runAIAction(.summarize) },
                onExtractActionItems: { runAIAction(.actionItems) },
                onRewrite: { runAIAction(.rewrite) },
                result: aiResult,
                isLoading: isLoading
            )
            .listRowSeparator(.hidden)
        }
        .listStyle(.plain)
        .navigationTitle("Meeting Notes")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            notes = notesManager.notes(for: sessionStorageKey)
        }
        .onChange(of: manager.currentSession?.sessionId, initial: false) { _, _ in
            notes = notesManager.notes(for: sessionStorageKey)
        }
    }

    private var sessionStorageKey: String {
        manager.currentSession?.sessionId ?? ""
    }

    private enum AIAction: Sendable {
        case summarize
        case actionItems
        case rewrite
    }

    private func saveNotes() {
        notesManager.setNotes(notes, for: sessionStorageKey)
    }

    private func runAIAction(_ action: AIAction) {
        saveNotes()
        isLoading = true
        aiResult = ""
        Task {
            defer { isLoading = false }
            do {
                switch action {
                case .summarize:
                    aiResult = try await notesManager.summarize(notes: notes)
                case .actionItems:
                    aiResult = try await notesManager.extractActionItems(notes: notes)
                case .rewrite:
                    aiResult = try await notesManager.rewrite(notes: notes)
                }
            } catch {
                aiResult = "AI request failed: \(error.localizedDescription)"
            }
        }
    }
}
