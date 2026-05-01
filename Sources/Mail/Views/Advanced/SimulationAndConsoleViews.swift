import SwiftUI

/// Panel for reply simulations and strategy suggestions.
struct SimulationPanel: View {
    let original: String
    @Binding var draft: String
    @State private var simulationResult: String = ""
    @State private var suggestions: [String] = []
    @State private var isSimulating = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Response Simulation", systemImage: "chart.bar.doc.horizontal.fill")
                .font(.headline)

            if isSimulating {
                HStack {
                    Spacer()
                    ProgressView("Simulating Outcomes...")
                    Spacer()
                }
            } else if !simulationResult.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Likely Outcome")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                    Text(simulationResult)
                        .font(.callout)
                        .padding(8)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                }
            }

            if !suggestions.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Alternative Strategies")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                    ForEach(suggestions, id: \.self) { strategy in
                        Button(action: { /* Apply strategy */ }) {
                            Text(strategy)
                                .font(.caption)
                                .padding(8)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.purple.opacity(0.05))
                                .cornerRadius(8)
                        }
                    }
                }
            }

            Button(action: runSimulation) {
                HStack {
                    Spacer()
                    Text("Run AI Simulation")
                    Spacer()
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(draft.isEmpty)
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(12)
        .onAppear(perform: loadStrategies)
    }

    private func runSimulation() {
        isSimulating = true
        Task {
            simulationResult = (try? await SafetySimulationEngine.shared.simulateReplyOutcome(original: original, reply: draft)) ?? "Simulation Failed"
            isSimulating = false
        }
    }

    private func loadStrategies() {
        Task {
            suggestions = (try? await SafetySimulationEngine.shared.suggestStrategies(original: original)) ?? []
        }
    }
}

/// Console for manual execution of advanced AI actions.
struct CommandConsole: View {
    @State private var command: String = ""
    @State private var history: [String] = []
    @State private var isExecuting = false

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(history, id: \.self) { entry in
                        Text("> \(entry)")
                            .font(.system(.caption, design: .monospaced))
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(Color.black.opacity(0.05))

            HStack {
                TextField("Type command (e.g., 'summarize thread', 'schedule meeting')", text: $command)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.subheadline, design: .monospaced))

                Button(action: execute) {
                    if isExecuting {
                        ProgressView()
                    } else {
                        Image(systemName: "terminal.fill")
                    }
                }
                .disabled(command.isEmpty || isExecuting)
            }
            .padding()
            .background(Color(uiColor: .systemBackground))
        }
        .navigationTitle("Command Console")
    }

    private func execute() {
        isExecuting = true
        let cmd = command
        command = ""
        Task {
            let results = try? await EmailCommandEngine.shared.processCommands(in: cmd)
            history.append(cmd)
            if let results, !results.isEmpty {
                history.append(contentsOf: results.map { "  Executed: \($0)" })
            } else {
                history.append("  No command recognized.")
            }
            isExecuting = false
        }
    }
}
