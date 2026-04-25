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

                        Button(action: { showingOptimizer = true }) {
                            Label("Optimize with AI", systemImage: "sparkles")
                                .font(.subheadline.bold())
                        }
                        .disabled(prompt.isEmpty)
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
            .sheet(isPresented: $showingOptimizer) {
                AgentPromptOptimizerView(originalPrompt: prompt, optimizedPrompt: $prompt)
            }
            .background(
                NavigationLink(destination: AgentProgressSessionView(prompt: prompt, owner: owner, repo: repo, branch: nil), isActive: $navigateToProgress) {
                    EmptyView()
                }
            )
        }
    }

    private func startTask() {
        navigateToProgress = true
    }
}
