import SwiftUI

struct SpeechPresetPromptsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var prompts: [SpeechPresetPrompt] = SpeechPresetPrompts.all

    var onSelect: (String) -> Void

    var categories: [String] {
        Array(Set(SpeechPresetPrompts.all.map { $0.category })).sorted()
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(categories, id: \.self) { category in
                    Section(category) {
                        ForEach(filteredPrompts.filter { $0.category == category }) { prompt in
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
                            }
                        }
                    }
                }
            }
            .navigationTitle("AI Prompts")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search prompts...")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        prompts.shuffle()
                    } label: {
                        Label("Shuffle", systemImage: "shuffle")
                    }
                }
            }
        }
    }

    var filteredPrompts: [SpeechPresetPrompt] {
        if searchText.isEmpty {
            return prompts
        }
        return prompts.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.prompt.localizedCaseInsensitiveContains(searchText)
        }
    }
}
