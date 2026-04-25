import SwiftUI

struct AgentPromptView: View {
    let owner: String
    let repo: String

    @State private var prompt: String = ""
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @Environment(\.dismiss) var dismiss

    let templates = [
        ("Fix bugs", "Find and fix common bugs in this repository."),
        ("Add tests", "Write unit tests for the core logic of this app."),
        ("Refactor code", "Refactor the existing code for better readability and performance."),
        ("Documentation", "Generate README or inline documentation for the source files.")
    ]

    var body: some View {
        NavigationView {
            VStack {
                Form {
                    Section("What should Jules do?") {
                        TextEditor(text: $prompt)
                            .frame(minHeight: 150)
                            .overlay(
                                Group {
                                    if prompt.isEmpty {
                                        Text("Describe the task...")
                                            .foregroundColor(.secondary)
                                            .padding(.horizontal, 4)
                                            .padding(.vertical, 8)
                                    }
                                },
                                alignment: .topLeading
                            )
                    }

                    Section("Templates") {
                        ForEach(templates, id: \.0) { title, template in
                            Button(action: { prompt = template }) {
                                HStack {
                                    Text(title)
                                    Spacer()
                                    Image(systemName: "arrow.right.circle")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                }

                if let error = errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .padding()
                }

                Button(action: startTask) {
                    if isSubmitting {
                        ProgressView().tint(.white)
                    } else {
                        Text("Start Agent Task")
                            .font(.headline)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(prompt.isEmpty ? Color.gray : Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
                .padding()
                .disabled(prompt.isEmpty || isSubmitting)
            }
            .navigationTitle("New Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func startTask() {
        isSubmitting = true
        errorMessage = nil

        Task {
            do {
                let _ = try await AgentSessionManager.shared.startSession(prompt: prompt, owner: owner, repo: repo)
                await MainActor.run {
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = AgentErrorHandler.handle(error)
                    isSubmitting = false
                }
            }
        }
    }
}
