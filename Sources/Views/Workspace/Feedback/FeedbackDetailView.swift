import SwiftUI

struct FeedbackDetailView: View {
    let feedback: Feedback
    let onUpdated: (Feedback) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var status: FeedbackStatus
    @State private var priority: FeedbackPriority
    @State private var assignedTo: String
    @State private var internalNotes: String

    @State private var isSaving = false
    @State private var errorMessage: String?

    init(feedback: Feedback, onUpdated: @escaping (Feedback) -> Void) {
        self.feedback = feedback
        self.onUpdated = onUpdated
        _status = State(initialValue: feedback.statusValue)
        _priority = State(initialValue: feedback.priorityValue)
        _assignedTo = State(initialValue: feedback.assignedTo ?? "")
        _internalNotes = State(initialValue: feedback.internalNotes)
    }

    var body: some View {
        Form {
            Section("Message") {
                Text(feedback.message)
                    .font(.body)
            }

            Section("Reporter") {
                LabeledContent("Name", value: feedback.userName)
                if let userId = feedback.userId {
                    LabeledContent("User ID", value: userId)
                }
            }

            Section("Environment") {
                LabeledContent("Device", value: feedback.device)
                LabeledContent("App Version", value: feedback.appVersion)
                LabeledContent("Created", value: feedback.createdAt.formatted(date: .abbreviated, time: .shortened))
            }

            Section("Moderation") {
                Picker("Status", selection: $status) {
                    ForEach(FeedbackStatus.allCases) { value in
                        Text(value.displayName).tag(value)
                    }
                }

                Picker("Priority", selection: $priority) {
                    ForEach(FeedbackPriority.allCases) { value in
                        Text(value.displayName).tag(value)
                    }
                }

                TextField("Assigned developer", text: $assignedTo)
            }

            Section("Internal Notes") {
                TextEditor(text: $internalNotes)
                    .frame(minHeight: 140)
            }

            if let errorMessage {
                Section {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }

            Section {
                Button {
                    saveChanges()
                } label: {
                    HStack {
                        if isSaving {
                            ProgressView()
                        }
                        Text(isSaving ? "Saving..." : "Save Changes")
                    }
                    .frame(maxWidth: .infinity)
                }
                .disabled(isSaving)
            }
        }
        .navigationTitle("Feedback Detail")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func saveChanges() {
        isSaving = true
        errorMessage = nil

        let assigneeTrimmed = assignedTo.trimmingCharacters(in: .whitespacesAndNewlines)
        let notesTrimmed = internalNotes.trimmingCharacters(in: .whitespacesAndNewlines)

        Task {
            do {
                if status != feedback.statusValue {
                    try await FeedbackService.shared.updateStatus(feedbackId: feedback.id, status: status)
                }

                if priority != feedback.priorityValue {
                    try await FeedbackService.shared.updatePriority(feedbackId: feedback.id, priority: priority)
                }

                if assigneeTrimmed != (feedback.assignedTo ?? "").trimmingCharacters(in: .whitespacesAndNewlines) {
                    try await FeedbackService.shared.assignFeedback(
                        feedbackId: feedback.id,
                        assignee: assigneeTrimmed
                    )
                }

                if notesTrimmed != feedback.internalNotes.trimmingCharacters(in: .whitespacesAndNewlines) {
                    try await FeedbackService.shared.updateNotes(feedbackId: feedback.id, notes: notesTrimmed)
                }

                var updated = feedback
                updated.status = status.rawValue
                updated.priority = priority.rawValue
                updated.assignedTo = assigneeTrimmed.isEmpty ? nil : assigneeTrimmed
                updated.internalNotes = notesTrimmed
                updated.lastUpdatedAt = Date()

                await MainActor.run {
                    isSaving = false
                    onUpdated(updated)
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isSaving = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}
