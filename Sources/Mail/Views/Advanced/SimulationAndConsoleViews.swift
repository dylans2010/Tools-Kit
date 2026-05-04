import SwiftUI

/// Panel for reply simulations and strategy suggestions.
struct SimulationPanel: View {
    let original: String
    @Binding var draft: String
    @State private var simulationResult: String = ""
    @State private var suggestions: [String] = []
    @State private var isSimulating = false
    @State private var currentSentiment: String = "Analyzing..."

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Label("Response Simulation", systemImage: "chart.bar.doc.horizontal.fill")
                    .font(.headline)
                Spacer()
                Text(currentSentiment)
                    .font(.caption.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .foregroundStyle(.blue)
                    .clipShape(Capsule())
            }

            if isSimulating {
                HStack {
                    Spacer()
                    VStack(spacing: 12) {
                        ProgressView()
                        Text("Simulating Outcomes...")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding(.vertical, 20)
            } else if !simulationResult.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Projected Outcome")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)

                    Text(simulationResult)
                        .font(.subheadline)
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.blue.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.blue.opacity(0.1), lineWidth: 1))
                }
            }

            if !suggestions.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Alternative Strategies")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)

                    ForEach(suggestions, id: \.self) { strategy in
                        Button {
                            withAnimation {
                                draft = "AI Suggestion: " + strategy + "\n\n" + draft
                            }
                        } label: {
                            HStack {
                                Image(systemName: "lightbulb.fill")
                                    .font(.caption)
                                    .foregroundStyle(.orange)
                                Text(strategy)
                                    .font(.caption)
                                    .multilineTextAlignment(.leading)
                                Spacer()
                                Image(systemName: "plus.circle")
                                    .font(.caption)
                            }
                            .padding(12)
                            .background(Color.workspaceSurface)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Button {
                runSimulation()
            } label: {
                HStack {
                    Spacer()
                    Image(systemName: "sparkles")
                    Text("Run AI Simulation")
                    Spacer()
                }
                .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .disabled(draft.isEmpty || isSimulating)
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .onAppear(perform: initialAnalysis)
    }

    private func initialAnalysis() {
        Task {
            let tone = try? await AIService.shared.assessEmailTone(text: original)
            await MainActor.run {
                currentSentiment = tone ?? "Neutral"
                loadStrategies()
            }
        }
    }

    private func runSimulation() {
        isSimulating = true
        Task {
            do {
                let result = try await SafetySimulationEngine.shared.simulateReplyOutcome(original: original, reply: draft)
                await MainActor.run {
                    simulationResult = result
                    isSimulating = false
                }
            } catch {
                await MainActor.run {
                    simulationResult = "Failed to simulate: \(error.localizedDescription)"
                    isSimulating = false
                }
            }
        }
    }

    private func loadStrategies() {
        Task {
            let res = try? await SafetySimulationEngine.shared.suggestStrategies(original: original)
            await MainActor.run {
                suggestions = res ?? []
            }
        }
    }
}
