import SwiftUI

/// Panel for strategy and suggestions during negotiations.
struct NegotiationAssistantPanel: View {
    let thread: MailThread
    @State private var state: NegotiationState?
    @State private var isLoading = false

    var body: some View {
        WorkspaceSurfaceCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Label("Negotiation Intel", systemImage: "hand.raised.fill")
                        .font(.headline)
                    Spacer()
                    if isLoading {
                        ProgressView()
                    } else {
                        Text(state?.currentPhase.rawValue.capitalized ?? "Inactive")
                            .font(.caption.bold())
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.orange.opacity(0.1))
                            .foregroundStyle(.orange)
                            .clipShape(Capsule())
                    }
                }

                if let state {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Suggested Strategy")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                        Text(state.suggestedStrategy)
                            .font(.callout)
                    }

                    Divider()

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Commitments Tracked")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                        ForEach(state.commitments, id: \.self) { commitment in
                            HStack {
                                Image(systemName: "circle.fill")
                                    .font(.system(size: 6))
                                Text(commitment)
                                    .font(.caption)
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .onAppear(perform: analyze)
    }

    private func analyze() {
        isLoading = true
        Task {
            state = try? await NegotiationIntelligenceEngine.shared.analyzeNegotiation(for: thread)
            isLoading = false
        }
    }
}

/// Dashboard for commitments and overdue items.
struct DeadlineTrackerDashboard: View {
    @StateObject private var viewModel = PriorityQueueViewModel() // Reuse logic or specialized VM
    @State private var obligations: [DecisionEntry] = []
    @State private var isLoading = false

    var body: some View {
        List {
            Section("Upcoming Deadlines") {
                if isLoading {
                    ProgressView()
                } else if obligations.isEmpty {
                    Text("No Deadlines Detected")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(obligations) { entry in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(entry.title)
                                    .font(.subheadline.bold())
                                Text(entry.summary)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(entry.timestamp, style: .date)
                                .font(.caption2.bold())
                                .foregroundStyle(entry.timestamp < Date() ? .red : .blue)
                        }
                    }
                }
            }
        }
        .navigationTitle("Deadline Tracker")
        .onAppear(perform: loadObligations)
    }

    private func loadObligations() {
        isLoading = true
        Task {
            let allThreads = MailStorageService.shared.loadThreads(for: "all")
            var allObligations: [DecisionEntry] = []
            for thread in allThreads.prefix(10) {
                let threadObligations = try? await DeadlineCommitmentEngine.shared.extractObligations(for: thread)
                allObligations.append(contentsOf: threadObligations ?? [])
            }
            await MainActor.run {
                obligations = allObligations
                isLoading = false
            }
        }
    }
}
