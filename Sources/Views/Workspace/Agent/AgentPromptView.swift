import SwiftUI

struct AgentPromptView: View {
    let owner: String
    let repo: String

    @State private var prompt: String = ""
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @State private var showingOptimizer = false
    @State private var navigateToProgress = false
    @Environment(\.dismiss) var dismiss

    let templates = [
        ("Fix bugs", "Find and fix common bugs in this repository."),
        ("Add tests", "Write unit tests for the core logic of this app."),
        ("Refactor code", "Refactor the existing code for better readability and performance."),
        ("Documentation", "Generate README or inline documentation for the source files."),
        ("Optimize Performance", "Analyze the codebase for performance bottlenecks and implement optimizations."),
        ("Security Audit", "Perform a security audit and fix potential vulnerabilities."),
        ("Add Feature", "Implement a new feature based on the existing architectural patterns."),
        ("Modernize UI", "Update the SwiftUI views to use modern design principles and semantic styles.")
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                List {
                    Section {
                        VStack(alignment: .leading, spacing: 12) {
                            ZStack(alignment: .topLeading) {
                                if prompt.isEmpty {
                                    Text("Describe the task in detail...")
                                        .foregroundColor(.secondary)
                                        .padding(.horizontal, 4)
                                        .padding(.vertical, 8)
                                }
                                TextEditor(text: $prompt)
                                    .frame(minHeight: 180)
                                    .font(.body)
                            }

                            HStack {
                                Spacer()
                                Button(action: { showingOptimizer = true }) {
                                    Label("Optimize Prompt", systemImage: "sparkles")
                                        .font(.subheadline.weight(.semibold))
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.blue.opacity(0.1), in: Capsule())
                                }
                                .disabled(prompt.isEmpty)
                            }
                        }
                        .padding(.vertical, 4)
                    } header: {
                        Text("Task Objectives")
                    } footer: {
                        Text("Provide a clear description of what you want Jules to accomplish in this repository.")
                    }

                    Section("Quick Templates") {
                        ForEach(templates, id: \.0) { title, template in
                            Button {
                                withAnimation {
                                    prompt = template
                                }
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(title)
                                            .font(.subheadline.weight(.medium))
                                            .foregroundColor(.primary)
                                    }
                                    Spacer()
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundColor(.blue.opacity(0.8))
                                }
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)

                VStack(spacing: 12) {
                    if let error = errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }

                    Button(action: startTask) {
                        HStack {
                            if isSubmitting {
                                ProgressView().tint(.white)
                            } else {
                                Image(systemName: "play.fill")
                                Text("Launch Jules Agent")
                            }
                        }
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.secondary.opacity(0.3) : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(14)
                        .shadow(color: prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .clear : .blue.opacity(0.3), radius: 8, y: 4)
                    }
                    .disabled(prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSubmitting)
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
                .background(Color(.systemGroupedBackground))
            }
            .navigationTitle("Agent Prompt")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .sheet(isPresented: $showingOptimizer) {
                AgentPromptOptimizerView(originalPrompt: prompt, optimizedPrompt: $prompt)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
            .navigationDestination(isPresented: $navigateToProgress) {
                AgentProgressSessionView(prompt: prompt, owner: owner, repo: repo, branch: nil)
            }
        }
    }

    private func startTask() {
        let trimmedPrompt = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedPrompt.isEmpty else {
            errorMessage = "Prompt is required before launching Jules Agent."
            return
        }

        errorMessage = nil
        prompt = trimmedPrompt
        print("[AgentPromptView] Captured prompt (length: \(trimmedPrompt.count))")
        print("[AgentPromptView] Repository URL: https://github.com/\(owner)/\(repo)")
        navigateToProgress = true
    }
}
