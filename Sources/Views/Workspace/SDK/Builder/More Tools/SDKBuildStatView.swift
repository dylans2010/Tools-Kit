import SwiftUI

struct SDKBuildStatView: View {
    let stats = [
        BuildStat(name: "Average Build Time", value: "4.2s", trend: -0.5),
        BuildStat(name: "Binary Size", value: "12.4 MB", trend: 1.2),
        BuildStat(name: "Test Coverage", value: "88.5%", trend: 2.1),
        BuildStat(name: "Warning Count", value: "14", trend: -5.0)
    ]

    struct BuildStat: Identifiable {
        let id = UUID()
        let name: String
        let value: String
        let trend: Double
    }

    var body: some View {
        List {
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
}
