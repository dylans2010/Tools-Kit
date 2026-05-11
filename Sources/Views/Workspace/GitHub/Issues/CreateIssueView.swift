import SwiftUI

struct CreateIssueView: View {
    let repository: GitHubRepository
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var body = ""
    @State private var selectedLabels: Set<String> = []
    @State private var assignee = ""
    @State private var isSubmitting = false

    private let availableLabels = ["bug", "enhancement", "documentation", "question", "help wanted", "good first issue", "critical", "UI", "testing"]

    var body: some View {
        Form {
            Section("Issue Details") {
                TextField("Title", text: $title)
                TextEditor(text: $body)
                    .frame(minHeight: 120)
            }

            Section("Labels") {
                ForEach(availableLabels, id: \.self) { label in
                    Button {
                        if selectedLabels.contains(label) {
                            selectedLabels.remove(label)
                        } else {
                            selectedLabels.insert(label)
                        }
                    } label: {
                        HStack {
                            Text(label)
                            Spacer()
                            if selectedLabels.contains(label) {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                    .foregroundStyle(.primary)
                }
            }

            Section("Assignee") {
                TextField("Username (optional)", text: $assignee)
                    .autocorrectionDisabled()
            }
        }
        .navigationTitle("New Issue")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button {
                    submitIssue()
                } label: {
                    if isSubmitting {
                        ProgressView()
                    } else {
                        Text("Submit")
                    }
                }
                .disabled(title.isEmpty || isSubmitting)
            }
        }
    }

    private func submitIssue() {
        isSubmitting = true
        Task {
            try? await Task.sleep(nanoseconds: 500_000_000)
            await MainActor.run {
                isSubmitting = false
                dismiss()
            }
        }
    }
}
