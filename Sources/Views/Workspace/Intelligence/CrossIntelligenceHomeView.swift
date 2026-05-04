import SwiftUI

struct CrossIntelligenceHomeView: View {
    @StateObject private var orchestrator = AIOrchestrator.shared
    @State private var query = ""
    @State private var queryResult = ""
    @State private var isQuerying = false

    var body: some View {
        List {
            Section("Ask Intelligence") {
                VStack(alignment: .leading) {
                    TextField("Ask anything about your workspace...", text: $query)
                        .textFieldStyle(.roundedBorder)

                    Button(action: askAI) {
                        if isQuerying {
                            ProgressView()
                        } else {
                            Text("Ask AI")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(query.isEmpty || isQuerying)

                    if !queryResult.isEmpty {
                        Text(queryResult)
                            .font(.callout)
                            .padding()
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
                .padding(.vertical, 8)
            }

            Section("Insights") {
                if orchestrator.isAnalyzing {
                    HStack {
                        ProgressView()
                        Text("Analyzing workspace...")
                    }
                } else {
                    ForEach(orchestrator.globalInsights) { insight in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(insight.title)
                                    .font(.headline)
                                Spacer()
                                Text(insight.priority.rawValue.uppercased())
                                    .font(.caption2.bold())
                                    .foregroundColor(colorForPriority(insight.priority))
                            }
                            Text(insight.description)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .navigationTitle("Intelligence Hub")
        .refreshable {
            orchestrator.refreshInsights()
        }
    }

    private func askAI() {
        isQuerying = true
        Task {
            do {
                let result = try await orchestrator.performCrossAppQuery(query, apps: ["Notes", "Mail", "Tasks"])
                await MainActor.run {
                    self.queryResult = result
                    self.isQuerying = false
                }
            } catch {
                await MainActor.run {
                    self.queryResult = "Error: \(error.localizedDescription)"
                    self.isQuerying = false
                }
            }
        }
    }

    private func colorForPriority(_ p: IntelligenceInsight.Priority) -> Color {
        switch p {
        case .high: return .red
        case .medium: return .orange
        case .low: return .blue
        }
    }
}
