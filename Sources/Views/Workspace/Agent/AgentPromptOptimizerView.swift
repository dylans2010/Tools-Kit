import SwiftUI

struct AgentPromptOptimizerView: View {
    let originalPrompt: String
    @Binding var optimizedPrompt: String
    @Environment(\.dismiss) var dismiss

    @State private var result: String = ""
    @State private var isOptimizing = false
    @State private var error: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if isOptimizing {
                    VStack(spacing: 24) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(.blue)
                        Text("Please Wait...")
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemGroupedBackground))
                } else if let error = error {
                    VStack(spacing: 20) {
                        Image(systemName: "exclamationmark.bubble.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.orange)
                        Text("Optimization Failed")
                            .font(.headline)
                        Text(error)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                        Button(action: optimize) {
                            Label("Try Again", systemImage: "arrow.clockwise")
                                .font(.headline)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(Color.blue, in: Capsule())
                                .foregroundColor(.white)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemGroupedBackground))
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            HStack {
                                Image(systemName: "apple.intelligence")
                                    .foregroundColor(.blue)
                                Text("Agent Instructions")
                                    .font(.headline)
                            }
                            .padding(.top)

                            TextEditor(text: $result)
                                .frame(minHeight: 240)
                                .font(.system(.body, design: .monospaced))
                                .padding(12)
                                .background(Color(.secondarySystemGroupedBackground))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.blue.opacity(0.1), lineWidth: 1)
                                )

                            VStack(alignment: .leading, spacing: 8) {
                                Label("What Changed?", systemImage: "info.circle")
                                    .font(.caption.bold())
                                    .foregroundColor(.blue)
                                Text("The original prompt was expanded to include specific goals, technical constraints, and a more structured format optimized for Agent's capabilities.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineSpacing(4)
                            }
                            .padding()
                            .background(Color.blue.opacity(0.05), in: RoundedRectangle(cornerRadius: 10))
                        }
                        .padding()
                    }
                    .background(Color(.systemGroupedBackground))
                }

                if !isOptimizing && error == nil {
                    VStack(spacing: 12) {
                        Button(action: apply) {
                            Text("Use This Prompt")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(14)
                                .shadow(color: .blue.opacity(0.3), radius: 8, y: 4)
                        }

                        Button("Discard") {
                            dismiss()
                        }
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                }
            }
            .navigationTitle("Intelligence")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .task {
                optimize()
            }
        }
    }

    private func optimize() {
        isOptimizing = true
        error = nil

        let systemPrompt = """
        You are an expert prompt engineer for an AI coding agent named Jules.
        Your task is to take a user's potentially vague request and transform it into a highly specific, informational, and actionable agent prompt.
        The optimized prompt should:
        1. Explicitly state the goals.
        2. Mention technical details or patterns if relevant.
        3. Define scope clearly.
        4. Use a professional, directive tone.
        Return ONLY the optimized prompt text.
        """

        Task {
            do {
                let optimized = try await AIService.shared.processText(prompt: originalPrompt, systemPrompt: systemPrompt)
                await MainActor.run {
                    self.result = optimized
                    self.isOptimizing = false
                }
            } catch {
                await MainActor.run {
                    self.error = error.localizedDescription
                    self.isOptimizing = false
                }
            }
        }
    }

    private func apply() {
        optimizedPrompt = result
        dismiss()
    }
}
