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
                TextField("Ask Persona", text: $query)
                    .textInputAutocapitalization(.sentences)
                Button {
                    askPersona()
                } label: {
                    Label("Ask Persona", systemImage: "sparkles")
                }
                .disabled(query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isAsking)
            }

            Section {
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
            } header: {
                Text("Tuning")
            }

            if isAsking {
                Section {
                    ProgressView("Persona Is Thinking…")
                }
            }

            if let lastResponse {
                Section {
                    Text(lastResponse)
                } header: {
                    Text("Latest Response")
                }
            }

            Section {
                PersonaSuggestionRow(icon: "calendar.badge.clock", title: "Meeting Prep", detail: "Generate a quick briefing from recent notes.")
                PersonaSuggestionRow(icon: "chart.bar.xaxis", title: "Weekly Summary", detail: "Summarize your accomplishments for this week.")
                PersonaSuggestionRow(icon: "book.closed", title: "Knowledge Gaps", detail: "Find topics you have not revisited recently.")
            } header: {
                Text("Suggestions")
            }

            Section {
                if manager.interactions.isEmpty {
                    Text("No Interactions Yet")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(manager.interactions.reversed()) { interaction in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(interaction.query).font(.subheadline.weight(.semibold))
                            Text(interaction.response).font(.caption).foregroundStyle(.secondary).lineLimit(2)
                        }
                    }
                }
            } header: {
                Text("Recent History")
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

private struct PersonaSuggestionRow: View {
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
