import SwiftUI

struct SDKBuildStatView: View {
    @State private var stats = [
        BuildStat(name: "Average Build Time", value: "4.2s", trend: -0.5),
        BuildStat(name: "Binary Size", value: "12.4 MB", trend: 1.2),
        BuildStat(name: "Test Coverage", value: "88.5%", trend: 2.1),
        BuildStat(name: "Warning Count", value: "14", trend: -5.0)
    ]

    @State private var isAnalyzing = false
    @State private var lastUpdate = Date()

    struct BuildStat: Identifiable {
        let id = UUID()
        let name: String
        let value: String
        let trend: Double
    }

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Build Health")
                            .font(.headline)
                        Spacer()
                        if isAnalyzing {
                            ProgressView()
                        } else {
                            Button(action: runNewAnalysis) {
                                Label("Refresh", systemImage: "arrow.clockwise")
                                    .font(.caption.bold())
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                        }
                    }

                    Text("Last analysis: \(lastUpdate, style: .time)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }

            Section("Historical Performance") {
                ForEach(stats) { stat in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(stat.name).font(.subheadline).foregroundStyle(.secondary)
                            Text(stat.value).font(.headline)
                        }
                        Spacer()
                        HStack(spacing: 4) {
                            Image(systemName: stat.trend >= 0 ? "arrow.up.right" : "arrow.down.right")
                            Text("\(String(format: "%.1f", abs(stat.trend)))%")
                        }
                        .font(.caption.bold())
                        .foregroundStyle(stat.trend >= 0 ? (stat.name == "Binary Size" ? .red : .green) : (stat.name == "Average Build Time" ? .green : .red))
                    }
                }
            }

            Section("Resource Allocation") {
                LabeledContent("Thread Count", value: "8")
                LabeledContent("Memory Usage", value: "256 MB")
                LabeledContent("Cache Hit Rate", value: "92%")
            }
        }
        .navigationTitle("Build Statistics")
    }

    private func runNewAnalysis() {
        isAnalyzing = true

        // Simulate analysis delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isAnalyzing = false
            lastUpdate = Date()

            // Randomly update stats for demonstration
            stats = [
                BuildStat(name: "Average Build Time", value: String(format: "%.1fs", Double.random(in: 3.5...5.0)), trend: Double.random(in: -1.0...1.0)),
                BuildStat(name: "Binary Size", value: String(format: "%.1f MB", Double.random(in: 11.5...13.0)), trend: Double.random(in: -0.5...1.5)),
                BuildStat(name: "Test Coverage", value: String(format: "%.1f%%", Double.random(in: 85.0...92.0)), trend: Double.random(in: -1.0...2.5)),
                BuildStat(name: "Warning Count", value: "\(Int.random(in: 5...20))", trend: Double.random(in: -5.0...5.0))
            ]
        }
    }
}
