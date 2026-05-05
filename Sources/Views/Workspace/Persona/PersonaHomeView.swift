import SwiftUI

struct PersonaHomeView: View {
    @StateObject private var manager = PersonaManager.shared
    @State private var query = ""
    @State private var isAsking = false
    @State private var lastResponse: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header

                if isAsking {
                    ProgressView("Persona is thinking...")
                        .padding()
                } else if let response = lastResponse {
                    responseSection(response)
                }

                interactionHistory
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
