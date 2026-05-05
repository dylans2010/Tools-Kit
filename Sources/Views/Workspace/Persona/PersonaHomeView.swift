import SwiftUI

struct PersonaHomeView: View {
    @StateObject private var manager = PersonaManager.shared
    @State private var query = ""
    @State private var isAsking = false
    @State private var lastResponse: String?

    @State private var personaTone = "Professional"
    @State private var focusArea = "All Content"
    @State private var showingSettings = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header

                tuningSection

                if isAsking {
                    ProgressView("Persona is thinking...")
                        .padding()
                } else if let response = lastResponse {
                    responseSection(response)
                }

                proactiveSuggestions

                interactionHistory

                knowledgeContextManager
            }
            .padding()
        }
        .navigationTitle("AI Persona")
        .searchable(text: $query, prompt: "Ask your Persona...")
        .onSubmit(of: .search) {
            askPersona()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Workspace AI Persona")
                .font(.title2.bold())
            Text("An AI trained specifically on your notes, tasks, and collaboration data.")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    private func responseSection(_ response: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Response")
                .font(.headline)
            Text(response)
                .padding()
                .background(Color.purple.opacity(0.1))
                .cornerRadius(12)
        }
    }

    private var tuningSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Persona Tuning")
                .font(.headline)

            HStack {
                Picker("Tone", selection: $personaTone) {
                    Text("Professional").tag("Professional")
                    Text("Creative").tag("Creative")
                    Text("Analytical").tag("Analytical")
                    Text("Casual").tag("Casual")
                }
                .pickerStyle(.segmented)
            }

            HStack {
                Label("Focus Area", systemImage: "target")
                    .font(.caption)
                Spacer()
                Picker("", selection: $focusArea) {
                    Text("All Content").tag("All Content")
                    Text("Recent Only").tag("Recent Only")
                    Text("Notes Only").tag("Notes Only")
                    Text("Tasks Only").tag("Tasks Only")
                }
                .pickerStyle(.menu)
                .labelsHidden()
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }

    private var proactiveSuggestions: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Proactive Insights")
                .font(.headline)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    SuggestionCard(title: "Project Alpha", detail: "You haven't updated the roadmap in 3 days. Need a summary of recent Slack discussions?")
                    SuggestionCard(title: "Meeting Prep", detail: "You have a call with Design in 1 hour. I've prepared a brief of your last 3 notes.")
                    SuggestionCard(title: "Habit Check", detail: "You've been very productive with Swift coding lately. Want to see a weekly summary?")
                }
            }
        }
    }

    private var knowledgeContextManager: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Knowledge Context")
                .font(.headline)

            VStack(spacing: 0) {
                ContextToggleRow(title: "Notebooks", isOn: .constant(true))
                Divider()
                ContextToggleRow(title: "Tasks & Habits", isOn: .constant(true))
                Divider()
                ContextToggleRow(title: "Collaborations", isOn: .constant(false))
                Divider()
                ContextToggleRow(title: "External (GitHub/Slack)", isOn: .constant(true))
            }
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
        }
    }

    private var interactionHistory: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("History")
                .font(.headline)

            if manager.interactions.isEmpty {
                Text("No interactions yet.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                ForEach(manager.interactions.reversed()) { interaction in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(interaction.query)
                            .font(.subheadline.bold())
                        Text(interaction.response)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                        Text(interaction.timestamp, style: .relative)
                            .font(.caption2)
                            .foregroundColor(.tertiary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(12)
                }
            }
        }
    }

    private func askPersona() {
        guard !query.isEmpty else { return }
        isAsking = true
        let currentQuery = query
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

struct SuggestionCard: View {
    let title: String
    let detail: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.bold())
                .foregroundColor(.purple)
            Text(detail)
                .font(.system(size: 13))
                .foregroundColor(.primary)
                .lineLimit(3)

            Button("Action") { }
                .font(.caption.bold())
                .buttonStyle(.bordered)
                .tint(.purple)
        }
        .padding()
        .frame(width: 200, height: 140, alignment: .topLeading)
        .background(Color.purple.opacity(0.05))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.purple.opacity(0.2), lineWidth: 1)
        )
    }
}

struct ContextToggleRow: View {
    let title: String
    @Binding var isOn: Bool

    var body: some View {
        Toggle(title, isOn: $isOn)
            .padding()
            .font(.subheadline)
    }
}
