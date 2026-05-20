import SwiftUI

struct EssayDraftingView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var manager = NotebooksManager.shared

    // Inputs
    @State private var topic: String = ""
    @State private var goal: String = "Inform"
    @State private var thesis: String = ""
    @State private var keyPoints: [String] = [""]
    @State private var tone: String = "Academic"
    @State private var complexity: String = "Standard"
    @State private var lengthTarget: String = "1000 words"
    @State private var audience: String = "General"
    @State private var formattingStyle: String = "APA"
    @State private var struggle: String = "Starting"
    @State private var hookEnabled: Bool = true
    @State private var sourceRequirement: String = "None"
    @State private var outputMode: String = "Full essay"
    @State private var styleReference: String = ""
    @State private var keywords: String = ""

    // UI State
    @State private var currentStep: Int = 1
    @State private var isGenerating: Bool = false
    @State private var generatedResult: String = ""
    @State private var showPreview: Bool = false
    @State private var suggestedThesisLoading: Bool = false

    let goals = ["Inform", "Argue", "Analyze", "Reflect"]
    let tones = ["Academic", "Professional", "Casual", "Creative"]
    let complexities = ["Basic", "Standard", "Advanced", "Academic Expert"]
    let formattingStyles = ["APA", "MLA", "Chicago", "Harvard"]
    let struggles = ["Starting", "Organizing", "Making arguments", "Grammar"]
    let sourceRequirements = ["None", "Light", "Strict"]
    let outputModes = ["Full essay", "Outline only", "Paragraph-by-paragraph"]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                stepIndicator

                ScrollView {
                    VStack(spacing: 24) {
                        if !showPreview {
                            stepContent
                        } else {
                            previewContent
                        }
                    }
                    .padding()
                }

                if !showPreview {
                    navigationButtons
                }
            }
            .navigationTitle("Essay Drafting")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private var stepIndicator: some View {
        HStack(spacing: 4) {
            ForEach(1...5, id: \.self) { step in
                Rectangle()
                    .fill(currentStep >= step ? Color.accentColor : Color.secondary.opacity(0.3))
                    .frame(height: 4)
                    .cornerRadius(2)
            }
        }
        .padding()
    }

    @ViewBuilder
    private var stepContent: some View {
        switch currentStep {
        case 1:
            VStack(alignment: .leading, spacing: 20) {
                Text("What are you writing about?").font(.title2.bold())

                VStack(alignment: .leading, spacing: 8) {
                    Text("Topic or Prompt").font(.headline)
                    TextEditor(text: $topic)
                        .frame(height: 100)
                        .padding(8)
                        .background(Color(uiColor: .secondarySystemGroupedBackground))
                        .cornerRadius(12)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Essay Goal").font(.headline)
                    Picker("Goal", selection: $goal) {
                        ForEach(goals, id: \.self) { Text($0) }
                    }
                    .pickerStyle(.segmented)
                }
            }
        case 2:
            VStack(alignment: .leading, spacing: 20) {
                Text("Define your core thesis").font(.title2.bold())

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Thesis Statement").font(.headline)
                        Spacer()
                        if suggestedThesisLoading {
                            ProgressView().scaleEffect(0.8)
                        } else {
                            Button("Suggest") {
                                suggestThesis()
                            }
                            .font(.caption)
                        }
                    }
                    TextEditor(text: $thesis)
                        .frame(height: 80)
                        .padding(8)
                        .background(Color(uiColor: .secondarySystemGroupedBackground))
                        .cornerRadius(12)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Key Points").font(.headline)
                    ForEach(0..<keyPoints.count, id: \.self) { index in
                        HStack {
                            TextField("Key point \(index + 1)", text: $keyPoints[index])
                                .textFieldStyle(.roundedBorder)
                            if keyPoints.count > 1 {
                                Button(action: { keyPoints.remove(at: index) }) {
                                    Image(systemName: "minus.circle.fill").foregroundColor(.red)
                                }
                            }
                        }
                    }
                    Button(action: { keyPoints.append("") }) {
                        Label("Add Key Point", systemImage: "plus.circle.fill")
                    }
                }
            }
        case 3:
            VStack(alignment: .leading, spacing: 20) {
                Text("Style & Audience").font(.title2.bold())

                Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 16) {
                    GridRow {
                        VStack(alignment: .leading) {
                            Text("Tone").font(.headline)
                            Picker("Tone", selection: $tone) {
                                ForEach(tones, id: \.self) { Text($0) }
                            }
                            .pickerStyle(.menu)
                        }
                        VStack(alignment: .leading) {
                            Text("Complexity").font(.headline)
                            Picker("Complexity", selection: $complexity) {
                                ForEach(complexities, id: \.self) { Text($0) }
                            }
                            .pickerStyle(.menu)
                        }
                    }
                    GridRow {
                        VStack(alignment: .leading) {
                            Text("Audience").font(.headline)
                            TextField("e.g. Students", text: $audience)
                                .textFieldStyle(.roundedBorder)
                        }
                        VStack(alignment: .leading) {
                            Text("Length Target").font(.headline)
                            TextField("e.g. 1000 words", text: $lengthTarget)
                                .textFieldStyle(.roundedBorder)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Formatting Style").font(.headline)
                    Picker("Formatting", selection: $formattingStyle) {
                        ForEach(formattingStyles, id: \.self) { Text($0) }
                    }
                    .pickerStyle(.segmented)
                }
            }
        case 4:
            VStack(alignment: .leading, spacing: 20) {
                Text("Smart Refinements").font(.title2.bold())

                VStack(alignment: .leading, spacing: 8) {
                    Text("What do you struggle with most?").font(.headline)
                    Picker("Struggle", selection: $struggle) {
                        ForEach(struggles, id: \.self) { Text($0) }
                    }
                    .pickerStyle(.menu)
                }

                Toggle("Include Compelling Hook", isOn: $hookEnabled)
                    .font(.headline)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Source Citation Requirements").font(.headline)
                    Picker("Sources", selection: $sourceRequirement) {
                        ForEach(sourceRequirements, id: \.self) { Text($0) }
                    }
                    .pickerStyle(.segmented)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Keywords (Optional)").font(.headline)
                    TextField("Enter keywords separated by commas", text: $keywords)
                        .textFieldStyle(.roundedBorder)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Style Reference / Sample (Optional)").font(.headline)
                    TextEditor(text: $styleReference)
                        .frame(height: 80)
                        .padding(8)
                        .background(Color(uiColor: .secondarySystemGroupedBackground))
                        .cornerRadius(12)
                }
            }
        case 5:
            VStack(alignment: .leading, spacing: 20) {
                Text("Finalize Generation").font(.title2.bold())

                VStack(alignment: .leading, spacing: 12) {
                    Text("Output Mode").font(.headline)
                    ForEach(outputModes, id: \.self) { mode in
                        Button(action: { outputMode = mode }) {
                            HStack {
                                Text(mode)
                                Spacer()
                                if outputMode == mode {
                                    Image(systemName: "checkmark.circle.fill").foregroundColor(.accentColor)
                                }
                            }
                            .padding()
                            .background(Color(uiColor: .secondarySystemGroupedBackground))
                            .cornerRadius(12)
                        }
                        .foregroundColor(.primary)
                    }
                }

                Button(action: generateEssay) {
                    HStack {
                        if isGenerating {
                            ProgressView().tint(.white).padding(.trailing, 8)
                        }
                        Text(isGenerating ? "Generating..." : "Generate Essay")
                            .bold()
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(isGenerating || topic.isEmpty)
            }
        default:
            EmptyView()
        }
    }

    private var navigationButtons: some View {
        HStack {
            if currentStep > 1 {
                Button("Previous") {
                    withAnimation { currentStep -= 1 }
                }
                .buttonStyle(.bordered)
            }

            Spacer()

            if currentStep < 5 {
                Button("Next") {
                    withAnimation { currentStep += 1 }
                }
                .buttonStyle(.borderedProminent)
                .disabled(currentStep == 1 && topic.isEmpty)
            }
        }
        .padding()
    }

    private var previewContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("Generated Content").font(.title2.bold())
                Spacer()
                Button("Edit Inputs") {
                    showPreview = false
                }
                .font(.caption)
            }

            ScrollView {
                Text((try? AttributedString(markdown: generatedResult)) ?? AttributedString(generatedResult))
                    .padding()
                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                    .cornerRadius(12)
            }
            .frame(maxHeight: 500)

            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    Button(action: addToNote) {
                        Label("Add To Note", systemImage: "plus.square.on.square")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)

                    Button(action: generateEssay) {
                        Label("Try Again", systemImage: "arrow.clockwise")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }

                Button(action: humanize) {
                    Label("Humanizer", systemImage: "person.badge.shield.checkmark")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
            }
        }
    }

    // MARK: - Actions

    private func suggestThesis() {
        guard !topic.isEmpty else { return }
        suggestedThesisLoading = true
        Task {
            do {
                let prompt = "Suggest a clear, compelling thesis statement for a \(goal) essay about: \(topic)"
                let result = try await AIService.shared.processText(prompt: prompt, systemPrompt: "You are an expert academic advisor. Provide only the thesis statement.")
                await MainActor.run {
                    self.thesis = result.trimmingCharacters(in: .whitespacesAndNewlines)
                    suggestedThesisLoading = false
                }
            } catch {
                suggestedThesisLoading = false
            }
        }
    }

    private func generateEssay() {
        isGenerating = true
        Task {
            do {
                var taskPrompt = "Generate a \(outputMode) for an essay."
                if outputMode == "Full essay" {
                    taskPrompt = "Generate a complete essay."
                } else if outputMode == "Outline only" {
                    taskPrompt = "Generate a detailed structured outline for an essay."
                } else if outputMode == "Paragraph-by-paragraph" {
                    taskPrompt = "Generate the first few paragraphs of an essay."
                }

                let context = """
                Topic: \(topic)
                Goal: \(goal)
                Thesis: \(thesis)
                Key Points: \(keyPoints.joined(separator: ", "))
                Tone: \(tone)
                Complexity: \(complexity)
                Length: \(lengthTarget)
                Audience: \(audience)
                Formatting Style: \(formattingStyle)
                User Struggle: \(struggle)
                Hook: \(hookEnabled ? "Yes" : "No")
                Source Requirements: \(sourceRequirement)
                Keywords: \(keywords)
                Style Reference: \(styleReference)
                """

                var systemPrompt = "You are a professional essay writer. "
                if struggle == "Starting" {
                    systemPrompt += "Prioritize a strong, engaging introduction and clear structural foundation. "
                } else if struggle == "Organizing" {
                    systemPrompt += "Ensure a highly logical flow and well-structured progression of ideas. "
                } else if struggle == "Making arguments" {
                    systemPrompt += "Focus on depth of reasoning, evidence-based claims, and persuasive strength. "
                } else if struggle == "Grammar" {
                    systemPrompt += "Ensure perfectly polished, sophisticated, and error-free writing. "
                }

                if hookEnabled {
                    systemPrompt += "Always start with a compelling opening hook. "
                } else {
                    systemPrompt += "Start directly with a formal academic introduction. "
                }

                if sourceRequirement == "Light" {
                    systemPrompt += "Include general references where appropriate. "
                } else if sourceRequirement == "Strict" {
                    systemPrompt += "Include properly formatted \(formattingStyle) citations for all major claims. "
                }

                if !styleReference.isEmpty {
                    systemPrompt += "Mimic the tone and structure of the provided style reference. "
                }

                if !keywords.isEmpty {
                    systemPrompt += "Naturally integrate the following keywords: \(keywords). "
                }

                let prompt = "\(taskPrompt)\n\nEssay Context:\n\(context)"

                let result = try await AIService.shared.processText(prompt: prompt, systemPrompt: systemPrompt)
                await MainActor.run {
                    self.generatedResult = result
                    self.isGenerating = false
                    self.showPreview = true
                }
            } catch {
                await MainActor.run {
                    self.generatedResult = "Error generating essay: \(error.localizedDescription)"
                    self.isGenerating = false
                    self.showPreview = true
                }
            }
        }
    }

    private func humanize() {
        isGenerating = true
        Task {
            do {
                let systemPrompt = """
                Rewrite the essay to sound natural and human-written.
                Use simple, clear language.
                Vary sentence structure and rhythm.
                Avoid robotic phrasing and repetitive patterns.
                Avoid overly formal or generic AI tone.
                Always maintain the original meaning.
                The rewritten result must feel authentic and indistinguishable from human writing.
                """

                let result = try await AIService.shared.processText(prompt: generatedResult, systemPrompt: systemPrompt)
                await MainActor.run {
                    self.generatedResult = result
                    self.isGenerating = false
                }
            } catch {
                isGenerating = false
            }
        }
    }

    private func addToNote() {
        if let nb = manager.notebooks.first, let folder = nb.folders.first {
            manager.addPage(to: folder.id, in: nb.id, title: "Draft: \(topic)", content: generatedResult)
        }
        dismiss()
    }
}
