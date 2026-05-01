import SwiftUI

struct SmartOrganizerView: View {
    @StateObject private var organizer = SmartOrganizer.shared
    let space: CollaborationSpace

    @State private var suggestions: [SmartOrganizer.RestructureSuggestion] = []
    @State private var isOrganizing = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Smart Organizer")
                        .font(.title2.bold())
                    Text("AI-powered suggestions to keep your workspace tidy.")
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)

                if isOrganizing {
                    VStack(spacing: 20) {
                        ProgressView()
                        Text("Analyzing workspace structure...")
                            .font(.caption)
                    }
                    .frame(maxWidth: .infinity, minHeight: 200)
                } else if suggestions.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 48))
                            .foregroundColor(.purple)
                        Button("Generate Suggestions") {
                            analyzeWorkspace()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .frame(maxWidth: .infinity, minHeight: 200)
                } else {
                    ForEach(suggestions) { suggestion in
                        SuggestionCard(suggestion: suggestion)
                    }
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Organizer")
    }

    private func analyzeWorkspace() {
        isOrganizing = true
        Task {
            let results = await organizer.generateSuggestions(for: space)
            await MainActor.run {
                self.suggestions = results
                self.isOrganizing = false

                // Mock suggestion for demo
                if self.suggestions.isEmpty {
                    self.suggestions = [
                        SmartOrganizer.RestructureSuggestion(objectID: UUID(), suggestedFolder: "Finances", reasoning: "This sheet contains budget data similar to other financial documents.")
                    ]
                }
            }
        }
    }
}

struct SuggestionCard: View {
    let suggestion: SmartOrganizer.RestructureSuggestion

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "folder.badge.plus")
                    .foregroundColor(.blue)
                Text("Move to \(suggestion.suggestedFolder)")
                    .font(.headline)
                Spacer()
                Button("Apply") { }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
            }

            Text(suggestion.reasoning)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}
