import SwiftUI

struct DraftSkillsView: View {
    let isAIGenerated: Bool
    @State private var name: String = ""
    @State private var content: String = ""
    @State private var category: String = "General"
    @State private var version: String = "1.0.0"
    @State private var priority: Int = 1

    // Wizard State
    @State private var wizardStep = 1
    @State private var purpose = ""
    @State private var tone = "Professional"
    @State private var constraints = ""

    @State private var isGenerating = false
    @Environment(\.dismiss) private var dismiss
    @StateObject private var skillsManager = AIService.SkillsManager.shared

    let categories = ["General", "Coding", "Writing", "Analysis", "Productivity", "Creative"]

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if isAIGenerated {
                    aiWizardSection
                }

                skillContentSection

                manualSettingsSection

                Button(action: saveSkill) {
                    Text(isWorking ? "Saving..." : "Create Skill")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.blue, in: RoundedRectangle(cornerRadius: 16))
                }
                .disabled(name.isEmpty || content.isEmpty || isGenerating)
                .padding(.horizontal)
            }
            .padding(.vertical, 20)
        }
        .background(Color(red: 0.05, green: 0.07, blue: 0.12).ignoresSafeArea())
        .navigationTitle(isAIGenerated ? "Generate Skill" : "New Skill")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var isWorking: Bool { isGenerating }

    // MARK: - AI Wizard

    private var aiWizardSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("Skill Generator Wizard", systemImage: "wand.and.stars")
                    .font(.headline)
                Spacer()
                Text("Step \(wizardStep) of 3")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)

            VStack(spacing: 12) {
                if wizardStep == 1 {
                    wizardQuestion(title: "1. What is the core objective of this skill?", placeholder: "e.g. Help me write high-quality Swift code following Clean Architecture...", text: $purpose)
                } else if wizardStep == 2 {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("2. What is the desired response tone?")
                            .font(.subheadline.bold())
                        Picker("Tone", selection: $tone) {
                            Text("Professional").tag("Professional")
                            Text("Technical").tag("Technical")
                            Text("Creative").tag("Creative")
                            Text("Concise").tag("Concise")
                        }
                        .pickerStyle(.segmented)
                    }
                } else {
                    wizardQuestion(title: "3. Any specific constraints or rules?", placeholder: "e.g. Use 2 spaces for indentation, never use force unwrap...", text: $constraints)
                }

                HStack {
                    if wizardStep > 1 {
                        Button("Back") { withAnimation { wizardStep -= 1 } }
                            .buttonStyle(.plain)
                            .foregroundStyle(.blue)
                    }
                    Spacer()
                    if wizardStep < 3 {
                        Button("Next") { withAnimation { wizardStep += 1 } }
                            .disabled(wizardStep == 1 && purpose.isEmpty)
                            .buttonStyle(.borderedProminent)
                    } else {
                        Button(action: generateSkill) {
                            if isGenerating {
                                ProgressView().tint(.white)
                            } else {
                                Text("Generate SKILL.md")
                            }
                        }
                        .disabled(purpose.isEmpty || isGenerating)
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
            .padding()
            .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.08)))
            .padding(.horizontal)
        }
    }

    private func wizardQuestion(title: String, placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.bold())
            TextEditor(text: text)
                .frame(height: 80)
                .padding(8)
                .background(Color.black.opacity(0.2), in: RoundedRectangle(cornerRadius: 8))
                .overlay(Text(text.wrappedValue.isEmpty ? placeholder : "").foregroundStyle(.secondary).padding(12), alignment: .topLeading)
        }
    }

    // MARK: - Skill Content

    private var skillContentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Skill Definition")
                .font(.headline)
                .padding(.horizontal)

            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Name")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                    TextField("Enter skill name", text: $name)
                        .padding()
                        .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("SKILL.md Content")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                    TextEditor(text: $content)
                        .frame(minHeight: 200)
                        .font(.system(.body, design: .monospaced))
                        .padding(8)
                        .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding()
            .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 20))
            .padding(.horizontal)
        }
    }

    // MARK: - Manual Settings

    private var manualSettingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Advanced Features")
                .font(.headline)
                .padding(.horizontal)

            VStack(spacing: 16) {
                HStack {
                    Text("Category")
                    Spacer()
                    Picker("Category", selection: $category) {
                        ForEach(categories, id: \.self) { cat in
                            Text(cat).tag(cat)
                        }
                    }
                    .pickerStyle(.menu)
                }

                HStack {
                    Text("Version")
                    Spacer()
                    TextField("1.0.0", text: $version)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                }

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Priority")
                        Spacer()
                        Text("\(priority)")
                            .foregroundStyle(.blue)
                            .bold()
                    }
                    Slider(value: Binding(get: { Double(priority) }, set: { priority = Int($0) }), in: 1...10, step: 1)
                }
            }
            .padding()
            .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 20))
            .padding(.horizontal)
        }
    }

    // MARK: - Logic

    private func generateSkill() {
        isGenerating = true
        Task {
            do {
                let complexPrompt = """
                Create a professional, highly-structured 'SKILL.md' file for an AI assistant.

                USER REQUIREMENTS:
                - Core Objective: \(purpose)
                - Desired Tone: \(tone)
                - Technical Constraints: \(constraints)

                The SKILL.md should follow this template:
                # Skill: [Name]
                ## Role Definition
                [Detailed description of the persona]
                ## Operational Rules
                [Strict rules for the AI to follow]
                ## Response Formatting
                [How the AI should structure its output]
                ## Knowledge Context
                [Domain specific focus]

                YOU MUST RETURN ONLY THE MARKDOWN CONTENT. NO EXPLANATIONS.
                """

                let systemInstructions = "You are a Master Prompt Engineer specialized in creating high-performance SKILL.md instruction files for LLMs. Your output is always precise, structured, and avoids any conversational filler. You only return markdown."

                let generated = try await AIService.shared.processText(prompt: complexPrompt, systemPrompt: systemInstructions)

                await MainActor.run {
                    content = generated
                    if name.isEmpty {
                        name = "New \(category) Skill"
                    }
                    isGenerating = false
                }
            } catch {
                await MainActor.run {
                    isGenerating = false
                }
            }
        }
    }

    private func saveSkill() {
        skillsManager.addSkill(name: name, content: content, category: category, version: version, priority: priority)
        dismiss()
    }
}
