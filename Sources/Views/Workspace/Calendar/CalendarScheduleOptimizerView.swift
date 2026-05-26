import SwiftUI

struct CalendarScheduleOptimizerView: View {
    @StateObject private var manager = CalendarManager.shared
    @State private var isOptimizing = false
    @State private var optimizationResult: [OptimizationSuggestion] = []

    struct OptimizationSuggestion: Identifiable {
        let id = UUID()
        let title: String
        let reason: String
        let action: String
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            List {
                if isOptimizing {
                    VStack(spacing: 20) {
                        ProgressView()
                        Text("Analyzing meeting patterns and availability...").font(.caption).foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                    .listRowBackground(Color.clear)
                } else if optimizationResult.isEmpty {
                    ContentUnavailableView("No Suggestions", systemImage: "sparkles", description: Text("Run the optimizer to find ways to reclaim your time."))
                } else {
                    Section("AI-Powered Suggestions") {
                        ForEach(optimizationResult) { suggestion in
                            VStack(alignment: .leading, spacing: 8) {
                                Text(suggestion.title).font(.subheadline.bold())
                                Text(suggestion.reason).font(.caption).foregroundStyle(.secondary)
                                Button(action: {}) {
                                    Text(suggestion.action)
                                        .font(.caption2.bold())
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(Color.accentColor.opacity(0.1), in: Capsule())
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
        }
        .navigationTitle("Schedule Optimizer")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: runOptimization) {
                    Label("Run", systemImage: "play.fill")
                }
                .disabled(isOptimizing)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Reclaim your time using AI analysis of your work habits.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(spacing: 20) {
                StatView(label: "Busy Score", value: "72%", color: .orange)
                StatView(label: "Deep Work", value: "4.5h", color: .green)
                StatView(label: "Meetings", value: "12", color: .blue)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
    }

    private func runOptimization() {
        isOptimizing = true
        optimizationResult = []

        Task {
            // Simulated AI processing
            try? await Task.sleep(nanoseconds: 2_000_000_000)

            await MainActor.run {
                optimizationResult = [
                    OptimizationSuggestion(
                        title: "Consolidate Meetings",
                        reason: "You have 3 scattered 30-min meetings on Wednesday that break up deep work blocks.",
                        action: "Move to afternoon block"
                    ),
                    OptimizationSuggestion(
                        title: "Early Finish Friday",
                        reason: "Historical data shows low productivity after 3 PM on Fridays.",
                        action: "Block 3-5 PM as Personal"
                    ),
                    OptimizationSuggestion(
                        title: "Morning Focus Block",
                        reason: "Your most productive hours are 8 AM - 10 AM, but it's currently used for admin tasks.",
                        action: "Auto-schedule admin to 4 PM"
                    )
                ]
                isOptimizing = false
            }
        }
    }
}

private struct StatView: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(.caption2).foregroundStyle(.secondary)
            Text(value).font(.headline).foregroundStyle(color)
        }
    }
}
