import SwiftUI

struct PersonaHomeView: View {
    @StateObject private var manager = PersonaManager.shared
    @State private var query = ""
    @State private var isAsking = false
    @State private var lastResponse: String?
    @State private var personaTone = "Professional"
    @State private var focusArea = "All Content"

    var body: some View {
        List {
            Section {
                TextField("Ask your Persona…", text: $query)
                    .textInputAutocapitalization(.sentences)
                Button {
                    askPersona()
                } label: {
                    Label("Ask Persona", systemImage: "sparkles")
                }
                .disabled(query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isAsking)
            }

            Section("Tuning") {
                Picker("Tone", selection: $personaTone) {
                    Text("Professional").tag("Professional")
                    Text("Creative").tag("Creative")
                    Text("Analytical").tag("Analytical")
                    Text("Casual").tag("Casual")
                }
                .pickerStyle(.segmented)

                Picker("Focus", selection: $focusArea) {
                    Text("All Content").tag("All Content")
                    Text("Recent").tag("Recent Only")
                    Text("Notes").tag("Notes Only")
                    Text("Tasks").tag("Tasks Only")
                }
            }

            if isAsking {
                Section {
                    ProgressView("Persona is thinking…")
                }
            }

            if let lastResponse {
                Section("Latest Response") {
                    Text(lastResponse)
                }
            }

            Section("Suggestions") {
                SuggestionRow(icon: "calendar.badge.clock", title: "Meeting Prep", detail: "Generate a quick briefing from recent notes.")
                SuggestionRow(icon: "chart.bar.xaxis", title: "Weekly Summary", detail: "Summarize your accomplishments for this week.")
                SuggestionRow(icon: "book.closed", title: "Knowledge Gaps", detail: "Find topics you have not revisited recently.")
            }

            Section("Recent History") {
                if manager.interactions.isEmpty {
                    Text("No interactions yet")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(manager.interactions.reversed()) { interaction in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(interaction.query).font(.subheadline.weight(.semibold))
                            Text(interaction.response).font(.caption).foregroundStyle(.secondary).lineLimit(2)
                        }
                    }
                }
            }
        }
        .navigationTitle("AI Persona")
    }

    private func askPersona() {
        let currentQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !currentQuery.isEmpty else { return }
        isAsking = true
        query = ""

        Task {
            do {
                let response = try await manager.queryPersona(query: currentQuery)
                await MainActor.run {
                    self.lastResponse = response
                    self.isAsking = false
                }
            } catch {
                await MainActor.run {
                    self.isAsking = false
                }
            }
        }
    }
}

private struct SuggestionRow: View {
    let icon: String
    let title: String
    let detail: String

    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline.weight(.semibold))
                Text(detail).font(.caption).foregroundStyle(.secondary)
            }
        } icon: {
            Image(systemName: icon)
                .foregroundStyle(.purple)
        }
    }
}
