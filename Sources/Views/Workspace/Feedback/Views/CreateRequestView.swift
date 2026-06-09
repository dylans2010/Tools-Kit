import SwiftUI

struct CreateRequestView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var description = ""
    @State private var category: FeedbackCategory = .workspace
    @State private var isSubmitting = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Request Details") {
                    TextField("Title", text: $title)
                    TextEditor(text: $description)
                        .frame(minHeight: 100)
                }

                Section("Category") {
                    Picker("Category", selection: $category) {
                        ForEach(FeedbackCategory.allCases) { cat in
                            Text(cat.displayName).tag(cat)
                        }
                    }
                }
            }
            .navigationTitle("New Feature Request")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Submit") {
                        submitRequest()
                    }
                    .disabled(title.isEmpty || description.isEmpty || isSubmitting)
                }
            }
        }
    }

    private func submitRequest() {
        isSubmitting = true
        Task {
            let request = FeedbackRequest(
                id: UUID(),
                title: title,
                description: description,
                votes: 1,
                hasVoted: true,
                category: category,
                status: "Under Review"
            )
            try? await FeedbackService.shared.submitFeatureRequest(request)
            isSubmitting = false
            dismiss()
        }
    }
}
