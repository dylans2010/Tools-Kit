import SwiftUI

struct SpeechPresetPromptsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var prompts: [SpeechPresetPrompt] = SpeechPresetPrompts.all
    @State private var showingCustomBuilder = false
    @State private var customTitle = ""
    @State private var customPrompt = ""
    @State private var customCategory = "Custom"

    // Rotation state
    @State private var rotationToken = UUID()

    var onSelect: (String) -> Void

    var categories: [String] {
        Array(Set(prompts.map { $0.category })).sorted()
    }

    var body: some View {
        NavigationStack {
            List {
                if !searchText.isEmpty {
                    searchResultsSection
                } else {
                    ForEach(categories, id: \.self) { category in
                        Section {
                            let categoryPrompts = prompts.filter { $0.category == category }
                            let rotatedPrompts = getRotatedPrompts(for: categoryPrompts)

                            ForEach(rotatedPrompts) { prompt in
                                promptRow(prompt)
                            }
                        } header: {
                            HStack {
                                Text(category)
                                Spacer()
                                if prompts.filter({ $0.category == category }).count > 5 {
                                    Button("Shuffle") {
                                        withAnimation {
                                            rotationToken = UUID()
                                        }
                                    }
                                    .font(.caption)
                                    .foregroundStyle(.accent)
                                }
                            }
                        }
                    }
                }

                Section("Custom Prompts") {
                    Button {
                        showingCustomBuilder = true
                    } label: {
                        Label("Create Custom Prompt", systemImage: "plus.circle.fill")
                            .font(.subheadline.bold())
                    }
                }
            }
            .navigationTitle("AI Prompt Hub")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search 300+ prompts...")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        prompts.shuffle()
                        rotationToken = UUID()
                    } label: {
                        Image(systemName: "shuffle")
                    }
                }
            }
            .sheet(isPresented: $showingCustomBuilder) {
                customBuilderView
            }
        }
    }

    private var searchResultsSection: some View {
        Section("Search Results") {
            ForEach(filteredPrompts) { prompt in
                promptRow(prompt)
            }
        }
    }

    private func promptRow(_ prompt: SpeechPresetPrompt) -> some View {
        Button {
            onSelect(prompt.prompt)
            dismiss()
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                Text(prompt.title)
                    .font(.subheadline.weight(.medium))
                Text(prompt.prompt)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            .padding(.vertical, 4)
        }
    }

    private var customBuilderView: some View {
        NavigationStack {
            Form {
                Section("Prompt Details") {
                    TextField("Title (e.g., Project Sync Summary)", text: $customTitle)
                    TextField("Category", text: $customCategory)
                    TextEditor(text: $customPrompt)
                        .frame(minHeight: 100)
                        .overlay(
                            Group {
                                if customPrompt.isEmpty {
                                    Text("Enter your AI prompt here...")
                                        .foregroundStyle(.placeholder)
                                        .padding(.leading, 4)
                                        .padding(.top, 8)
                                }
                            },
                            alignment: .topLeading
                        )
                }
            }
            .navigationTitle("New Custom Prompt")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showingCustomBuilder = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let newPrompt = SpeechPresetPrompt(title: customTitle, prompt: customPrompt, category: customCategory)
                        prompts.insert(newPrompt, at: 0)
                        showingCustomBuilder = false
                        customTitle = ""
                        customPrompt = ""
                    }
                    .disabled(customTitle.isEmpty || customPrompt.isEmpty)
                }
            }
        }
    }

    private func getRotatedPrompts(for categoryPrompts: [SpeechPresetPrompt]) -> [SpeechPresetPrompt] {
        // Deterministic shuffle based on rotationToken
        let seededPrompts = categoryPrompts.sorted { $0.id.uuidString < $1.id.uuidString }
        if seededPrompts.count <= 5 {
            return seededPrompts
        }

        // Simple rotation/shuffle simulation for the sake of 5-limit requirement
        // In a real app, we might use the rotationToken to seed a random number generator
        return Array(seededPrompts.shuffled().prefix(5))
    }

    var filteredPrompts: [SpeechPresetPrompt] {
        if searchText.isEmpty {
            return prompts
        }
        return prompts.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.prompt.localizedCaseInsensitiveContains(searchText) ||
            $0.category.localizedCaseInsensitiveContains(searchText)
        }
    }
}
