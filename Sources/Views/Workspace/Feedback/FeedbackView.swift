import SwiftUI

struct FeedbackView: View {
    @State private var message = ""
    @State private var selectedCategory: FeedbackCategory = .bug
    @State private var showStatusToUser = false
    @State private var isSubmitting = false
    @State private var submissionSucceeded = false
    @State private var errorMessage: String?

    private let minLength = 10

    var body: some View {
        SwiftUI.Group {
            if submissionSucceeded {
                FeedbackSuccessView {
                    message = ""
                    selectedCategory = .bug
                    showStatusToUser = false
                    submissionSucceeded = false
                    errorMessage = nil
                }
            } else {
                Form {
                    Section("Feedback") {
                        TextEditor(text: $message)
                            .frame(minHeight: 140)
                            .overlay(alignment: .topLeading) {
                                if message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                    Text("Tell us what happened, what you expected, and any context.")
                                        .foregroundStyle(.secondary)
                                        .padding(8)
                                        .allowsHitTesting(false)
                                }
                            }

                        Text("Minimum \(minLength) characters")
                            .font(.caption)
                            .foregroundStyle(isMessageValid ? .secondary : .red)
                    }

                    Section("Category") {
                        Picker("Category", selection: $selectedCategory) {
                            ForEach(FeedbackCategory.allCases) { category in
                                Text(category.displayName).tag(category)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    Section("Visibility") {
                        Toggle("Let me view submission status", isOn: $showStatusToUser)
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
                            submit()
                        } label: {
                            HStack {
                                if isSubmitting {
                                    ProgressView()
                                }
                                Text(isSubmitting ? "Submitting..." : "Submit Feedback")
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .disabled(!canSubmit)
                    }
                }
            }
        }
        .navigationTitle("Feedback")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink("My Feedback") {
                    MyFeedbackView()
                }
            }
        }
    }

    private var isMessageValid: Bool {
        message.trimmingCharacters(in: .whitespacesAndNewlines).count >= minLength
    }

    private var canSubmit: Bool {
        !isSubmitting && isMessageValid
    }

    private func submit() {
        let trimmed = message.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= minLength else { return }

        isSubmitting = true
        errorMessage = nil

        Task {
            do {
                _ = try await FeedbackService.shared.submitFeedback(
                    message: trimmed,
                    category: selectedCategory,
                    userCanViewStatus: showStatusToUser
                )

                await MainActor.run {
                    isSubmitting = false
                    submissionSucceeded = true
                }
            } catch {
                await MainActor.run {
                    isSubmitting = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}
