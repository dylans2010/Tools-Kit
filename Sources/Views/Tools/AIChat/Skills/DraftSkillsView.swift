import SwiftUI

struct DraftSkillsView: View {
    let isAIGenerated: Bool
    @State private var name: String = ""
    @State private var content: String = ""
    @State private var aiPrompt: String = ""
    @State private var isGenerating = false
    @Environment(\.dismiss) private var dismiss
    @StateObject private var skillsManager = AIService.SkillsManager.shared

    var body: some View {
        Form {
            if isAIGenerated {
                Section("AI Generation") {
                    TextField("What should this skill do?", text: $aiPrompt, axis: .vertical)
                        .lineLimit(3...5)
                    Button {
                        generateSkill()
                    } label: {
                        if isGenerating {
                            HStack {
                                ProgressView()
                                Text("Generating...")
                            }
                        } else {
                            Label("Generate Content", systemImage: "sparkles")
                        }
                    }
                    .disabled(aiPrompt.isEmpty || isGenerating)
                }
            }

            Section("Skill Content") {
                TextField("Skill Name", text: $name)
                TextEditor(text: $content)
                    .frame(minHeight: 200)
                    .font(.system(.body, design: .monospaced))
            }

            Section {
                Button("Add Skill") {
                    skillsManager.addSkill(name: name, content: content)
                    // We need to dismiss twice to get back to SkillsView
                    // but since this is usually in a sheet's NavigationStack:
                    dismiss()
                }
                .disabled(name.isEmpty || content.isEmpty)
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)
            }
        }
        .navigationTitle(isAIGenerated ? "Generate Skill" : "New Skill")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func generateSkill() {
        isGenerating = true
        Task {
            do {
                let prompt = "Generate a comprehensive 'skill.md' file content based on this description: \(aiPrompt). The content should be clear instructions for an AI assistant."
                let generated = try await AIService.shared.processText(prompt: prompt, systemPrompt: "You are an expert at writing system prompts and AI skills in markdown.")
                await MainActor.run {
                    content = generated
                    if name.isEmpty {
                        name = "New AI Skill"
                    }
                    isGenerating = false
                }
            } catch {
                await MainActor.run {
                    isGenerating = false
                    // Handle error (could add an alert)
                }
            }
        }
    }
}
